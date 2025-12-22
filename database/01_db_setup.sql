-- =====================================================
-- DATABASE CREATION
-- =====================================================

-- Create database only if it does not already exist
CREATE DATABASE IF NOT EXISTS hospital_management_system
    CHARACTER SET utf8mb4			# For recording Vietnamese names
    COLLATE utf8mb4_unicode_ci;		# For case-insensitive searching

-- Switch to the Hospital Management System database
USE hospital_management_system;

-- Set InnoDB as the default storage engine
SET default_storage_engine = INNODB;
