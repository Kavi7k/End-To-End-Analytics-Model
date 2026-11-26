-- ============================================================
-- 01_create_database.sql
-- Creates the E2E Analytics database and schemas
-- Run this first on SQL Server / SSMS
-- ============================================================

USE master;
GO

-- Create database (skip if it already exists)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'E2E_Analytics')
BEGIN
    CREATE DATABASE E2E_Analytics;
END
GO

USE E2E_Analytics;
GO

-- Create schemas
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg')
    EXEC('CREATE SCHEMA stg');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'clean')
    EXEC('CREATE SCHEMA clean');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'analytics')
    EXEC('CREATE SCHEMA analytics');
GO

PRINT '✅ Database and schemas created.';
GO
