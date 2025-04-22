/*
.SYNOPSIS
    Generic merge procedure for synchronizing source and target tables.

.DESCRIPTION
    Performs a generic MERGE operation between source and target tables,
    handling updates, inserts, and soft deletes with optional status tracking.

.PARAMETERS
    @SourceTable        - Source table name (including schema)
    @TargetTable        - Target table name (including schema)
    @PrimaryKeyColumns  - Comma-separated list of primary key columns
    @StatusColumn      - Optional column for tracking record status ('OK', 'Deleted')
    @AddedColumn      - Optional column for tracking when records were added
    @DeletedColumn    - Optional column for tracking when records were deleted
    @PrintSql         - Set to 1 to print the generated SQL without executing
    @ExecuteSql       - Set to 0 to prevent execution (useful with @PrintSql = 1)

.EXAMPLE
    EXEC [data].[GenericMerge]
        @SourceTable = 'staging.Customers',
        @TargetTable = 'data.Customers',
        @PrimaryKeyColumns = 'CustomerId',
        @StatusColumn = 'Status',
        @AddedColumn = 'Added',
        @DeletedColumn = 'Deleted',
        @PrintSql = 1,
        @ExecuteSql = 1

.NOTES
    - Usage in TimeXtender Data Enrichment:
        - Create the staging table in TX DE with all the required columns.
        - Duplicate the staging table in TX DE and rename it to the target table.
        - Add the Added, Deleted and Status columns to the target table as DateTime, DateTime and String respectively.
        - Add this script to the TX DE database
        - Create an Action that calls this procedure with the appropriate parameters.
    - Source and target tables must have matching column names
    
*/

CREATE OR ALTER PROCEDURE [data].[GenericMerge]
    @SourceTable NVARCHAR(MAX),
    @TargetTable NVARCHAR(MAX),
    @PrimaryKeyColumns NVARCHAR(MAX), -- Comma-separated list of primary key columns
    @StatusColumn NVARCHAR(MAX) = NULL,
    @AddedColumn NVARCHAR(MAX) = NULL,
    @DeletedColumn NVARCHAR(MAX) = NULL,
    @PrintSql BIT = 0, -- If 1, print the SQL instead of executing it
    @ExecuteSql BIT = 1 -- If 0, don't execute the SQL, useful for debugging to just print
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Declare variables
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @LoadDate NVARCHAR(MAX) = 'GETDATE()';
    DECLARE @OnClause NVARCHAR(MAX);
    DECLARE @UpdateSet NVARCHAR(MAX) = '';
    DECLARE @InsertColumns NVARCHAR(MAX) = '';
    DECLARE @InsertValues NVARCHAR(MAX) = '';
    DECLARE @DeleteClause NVARCHAR(MAX) = '';
 
    -- Construct the ON clause using the primary key columns
    SELECT @OnClause = STRING_AGG(
        CONCAT('target.[', value, '] = source.[', value, ']'),
        ' AND '
    )
    FROM STRING_SPLIT(@PrimaryKeyColumns, ',');
 
    -- Construct the UPDATE SET clause, ignoring columns that start with '__'
    SELECT @UpdateSet = STRING_AGG(
        CONCAT('target.[', c.name, '] = source.[', c.name, ']'),
        ', '
    )
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@TargetTable)
      AND c.name NOT LIKE '[__]%' -- Ignore columns starting with '__'
      AND c.name NOT IN (
          SELECT value FROM STRING_SPLIT(@PrimaryKeyColumns, ',')
      )
      AND c.name NOT IN (@StatusColumn, @AddedColumn, @DeletedColumn); -- Exclude optional columns
 
    -- Add optional Status column to the UPDATE clause
    IF @StatusColumn IS NOT NULL AND EXISTS (
        SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@TargetTable) AND name = @StatusColumn
    )
        SET @UpdateSet = CONCAT(@UpdateSet,
            CASE WHEN LEN(@UpdateSet) > 0 THEN ', ' ELSE '' END,
            'target.[', @StatusColumn, '] = ''OK''');
 
    -- Add optional ModifiedDate column to the UPDATE clause
    SET @UpdateSet = CONCAT(@UpdateSet,
        CASE WHEN LEN(@UpdateSet) > 0 THEN ', ' ELSE '' END,
        'target.[__ModifiedDate] = ', @LoadDate);
 
    -- Construct the INSERT clause, ignoring columns that start with '__' and excluding optional columns
    SELECT @InsertColumns = STRING_AGG(
        CONCAT('[', c.name, ']'),
        ', '
    )
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@TargetTable)
      AND c.name NOT LIKE '[__]%' -- Ignore columns starting with '__'
      AND c.name NOT IN (@StatusColumn, @AddedColumn, @DeletedColumn); -- Exclude optional columns
 
    SELECT @InsertValues = STRING_AGG(
        CONCAT('source.[', c.name, ']'),
        ', '
    )
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@SourceTable)
      AND c.name NOT LIKE '[__]%' -- Ignore columns starting with '__'
      AND c.name NOT IN (@StatusColumn, @AddedColumn, @DeletedColumn); -- Exclude optional columns
 
    -- Add optional Status and Added columns to the INSERT clause
    IF @StatusColumn IS NOT NULL AND EXISTS (
        SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@TargetTable) AND name = @StatusColumn
    )
    BEGIN
        SET @InsertColumns = CONCAT(@InsertColumns,
            CASE WHEN LEN(@InsertColumns) > 0 THEN ', ' ELSE '' END,
            '[', @StatusColumn, ']');
        SET @InsertValues = CONCAT(@InsertValues,
            CASE WHEN LEN(@InsertValues) > 0 THEN ', ' ELSE '' END,
            '''OK''');
    END
 
    IF @AddedColumn IS NOT NULL AND EXISTS (
        SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@TargetTable) AND name = @AddedColumn
    )
    BEGIN
        SET @InsertColumns = CONCAT(@InsertColumns,
            CASE WHEN LEN(@InsertColumns) > 0 THEN ', ' ELSE '' END,
            '[', @AddedColumn, ']');
        SET @InsertValues = CONCAT(@InsertValues,
            CASE WHEN LEN(@InsertValues) > 0 THEN ', ' ELSE '' END,
            @LoadDate);
    END
 
    IF @DeletedColumn IS NOT NULL AND EXISTS (
        SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@TargetTable) AND name = @DeletedColumn
    )
    BEGIN
        SET @InsertColumns = CONCAT(@InsertColumns,
            CASE WHEN LEN(@InsertColumns) > 0 THEN ', ' ELSE '' END,
            '[', @DeletedColumn, ']');
        SET @InsertValues = CONCAT(@InsertValues,
            CASE WHEN LEN(@InsertValues) > 0 THEN ', ' ELSE '' END,
            @LoadDate);
    END
 
    -- Construct the DELETE clause
    IF @DeletedColumn IS NOT NULL AND EXISTS (
        SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@TargetTable) AND name = @DeletedColumn
    )
    BEGIN
        SET @DeleteClause = CONCAT(
            'WHEN NOT MATCHED BY SOURCE THEN', CHAR(13),
            '    UPDATE SET', CHAR(13),
            '        target.[', @StatusColumn, '] = ''Deleted'',', CHAR(13),
            '        target.[', @DeletedColumn, '] = ', @LoadDate, ',', CHAR(13),
            '        target.[__ModifiedDate] = ', @LoadDate
        );
    END
 
    -- Construct the full MERGE statement with better formatting
    SET @Sql = CONCAT(
        'MERGE ', @TargetTable, ' AS target', CHAR(13),
        'USING ', @SourceTable, ' AS source', CHAR(13),
        'ON ', @OnClause, CHAR(13),
        'WHEN MATCHED THEN', CHAR(13),
        '    UPDATE SET ', @UpdateSet, CHAR(13),
        'WHEN NOT MATCHED BY TARGET THEN', CHAR(13),
        '    INSERT (', @InsertColumns, ')', CHAR(13),
        '    VALUES (', @InsertValues, ')', CHAR(13),
        @DeleteClause, ';'
    );
 
    -- Print or execute the SQL
    IF @PrintSql = 1
    BEGIN
        PRINT @Sql;
    END
    IF @ExecuteSql = 1
    BEGIN
        EXEC sp_executesql @Sql;
    END
END;