-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: hospital_management_system
-- ------------------------------------------------------
-- Server version	9.3.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `appointment`
--

DROP TABLE IF EXISTS `appointment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `appointment` (
  `appointment_id` int NOT NULL AUTO_INCREMENT,
  `patient_id` int NOT NULL,
  `doctor_id` int NOT NULL,
  `timeslot_id` int NOT NULL,
  `appointment_date` date NOT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci,
  `current_status` enum('CREATED','CONFIRMED','CANCELLED','COMPLETED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`appointment_id`),
  KEY `patient_id` (`patient_id`),
  KEY `doctor_id` (`doctor_id`),
  KEY `timeslot_id` (`timeslot_id`),
  CONSTRAINT `appointment_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`),
  CONSTRAINT `appointment_ibfk_2` FOREIGN KEY (`doctor_id`) REFERENCES `doctor` (`doctor_id`),
  CONSTRAINT `appointment_ibfk_3` FOREIGN KEY (`timeslot_id`) REFERENCES `timeslot` (`timeslot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `appointment_status_history`
--

DROP TABLE IF EXISTS `appointment_status_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `appointment_status_history` (
  `status_history_id` int NOT NULL AUTO_INCREMENT,
  `appointment_id` int NOT NULL,
  `old_status` enum('CREATED','CONFIRMED','CANCELLED','COMPLETED') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `new_status` enum('CREATED','CONFIRMED','CANCELLED','COMPLETED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `changed_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `changed_by` int NOT NULL,
  PRIMARY KEY (`status_history_id`),
  KEY `appointment_id` (`appointment_id`),
  KEY `changed_by` (`changed_by`),
  CONSTRAINT `appointment_status_history_ibfk_1` FOREIGN KEY (`appointment_id`) REFERENCES `appointment` (`appointment_id`),
  CONSTRAINT `appointment_status_history_ibfk_2` FOREIGN KEY (`changed_by`) REFERENCES `user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attachment`
--

DROP TABLE IF EXISTS `attachment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attachment` (
  `attachment_id` int NOT NULL AUTO_INCREMENT,
  `visit_id` int NOT NULL,
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `file_path` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `time_uploaded` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`attachment_id`),
  KEY `visit_id` (`visit_id`),
  CONSTRAINT `attachment_ibfk_1` FOREIGN KEY (`visit_id`) REFERENCES `visit` (`visit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `auditlog`
--

DROP TABLE IF EXISTS `auditlog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auditlog` (
  `audit_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `table_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `field_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `old_value` text COLLATE utf8mb4_unicode_ci,
  `new_value` text COLLATE utf8mb4_unicode_ci,
  `action_type` enum('INSERT','UPDATE','DELETE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `changed_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`audit_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `auditlog_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `department`
--

DROP TABLE IF EXISTS `department`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `department` (
  `department_id` int NOT NULL AUTO_INCREMENT,
  `department_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `department_leadership`
--

DROP TABLE IF EXISTS `department_leadership`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `department_leadership` (
  `leadership_id` int NOT NULL AUTO_INCREMENT,
  `department_id` int NOT NULL,
  `doctor_id` int NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  PRIMARY KEY (`leadership_id`),
  KEY `department_id` (`department_id`),
  KEY `doctor_id` (`doctor_id`),
  CONSTRAINT `department_leadership_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `department` (`department_id`),
  CONSTRAINT `department_leadership_ibfk_2` FOREIGN KEY (`doctor_id`) REFERENCES `doctor` (`doctor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `diagnosis`
--

DROP TABLE IF EXISTS `diagnosis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `diagnosis` (
  `diagnosis_id` int NOT NULL AUTO_INCREMENT,
  `diagnosis_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `diagnosis_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`diagnosis_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `doctor`
--

DROP TABLE IF EXISTS `doctor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `doctor` (
  `doctor_id` int NOT NULL AUTO_INCREMENT,
  `department_id` int NOT NULL,
  `full_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`doctor_id`),
  KEY `department_id` (`department_id`),
  CONSTRAINT `doctor_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `department` (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `doctor_availability`
--

DROP TABLE IF EXISTS `doctor_availability`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `doctor_availability` (
  `availability_id` int NOT NULL AUTO_INCREMENT,
  `doctor_id` int NOT NULL,
  `timeslot_id` int NOT NULL,
  `available_date` date NOT NULL,
  `is_available` tinyint(1) NOT NULL,
  PRIMARY KEY (`availability_id`),
  KEY `doctor_id` (`doctor_id`),
  KEY `timeslot_id` (`timeslot_id`),
  CONSTRAINT `doctor_availability_ibfk_1` FOREIGN KEY (`doctor_id`) REFERENCES `doctor` (`doctor_id`),
  CONSTRAINT `doctor_availability_ibfk_2` FOREIGN KEY (`timeslot_id`) REFERENCES `timeslot` (`timeslot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `financialtransaction`
--

DROP TABLE IF EXISTS `financialtransaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `financialtransaction` (
  `transaction_id` int NOT NULL AUTO_INCREMENT,
  `transaction_type` enum('INCOME','EXPENSE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `reference_type` enum('PATIENT_INVOICE','SUPPLIER_INVOICE','OTHER') COLLATE utf8mb4_unicode_ci NOT NULL,
  `reference_id` int NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `transaction_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`transaction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `login_history`
--

DROP TABLE IF EXISTS `login_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `login_history` (
  `login_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `login_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `login_status` enum('SUCCESS','FAILED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`login_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `login_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `medicalservice`
--

DROP TABLE IF EXISTS `medicalservice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `medicalservice` (
  `service_id` int NOT NULL AUTO_INCREMENT,
  `service_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `service_fee` decimal(10,2) NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`service_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification`
--

DROP TABLE IF EXISTS `notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification` (
  `notification_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `notification_type_id` int NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`notification_id`),
  KEY `user_id` (`user_id`),
  KEY `notification_type_id` (`notification_type_id`),
  CONSTRAINT `notification_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`),
  CONSTRAINT `notification_ibfk_2` FOREIGN KEY (`notification_type_id`) REFERENCES `notification_type` (`notification_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification_type`
--

DROP TABLE IF EXISTS `notification_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification_type` (
  `notification_type_id` int NOT NULL AUTO_INCREMENT,
  `type_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`notification_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `patient`
--

DROP TABLE IF EXISTS `patient`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `patient` (
  `patient_id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_of_birth` date NOT NULL,
  `gender` enum('Male','Female','Other') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`patient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `patientinvoice`
--

DROP TABLE IF EXISTS `patientinvoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `patientinvoice` (
  `patient_invoice_id` int NOT NULL AUTO_INCREMENT,
  `visit_id` int NOT NULL,
  `invoice_date` date NOT NULL,
  `total_amount` decimal(15,2) DEFAULT NULL,
  `status` enum('PAID','NOT PAID') COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`patient_invoice_id`),
  KEY `visit_id` (`visit_id`),
  CONSTRAINT `patientinvoice_ibfk_1` FOREIGN KEY (`visit_id`) REFERENCES `visit` (`visit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `patientinvoice_item`
--

DROP TABLE IF EXISTS `patientinvoice_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `patientinvoice_item` (
  `patient_invoice_item_id` int NOT NULL AUTO_INCREMENT,
  `patient_invoice_id` int NOT NULL,
  `item_type` enum('SERVICE','MEDICINE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `reference_id` int NOT NULL,
  `quantity` int NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `line_total` decimal(12,2) NOT NULL,
  PRIMARY KEY (`patient_invoice_item_id`),
  KEY `patient_invoice_id` (`patient_invoice_id`),
  CONSTRAINT `patientinvoice_item_ibfk_1` FOREIGN KEY (`patient_invoice_id`) REFERENCES `patientinvoice` (`patient_invoice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payment`
--

DROP TABLE IF EXISTS `payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `invoice_id` int NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `amount` decimal(12,2) NOT NULL,
  `payment_method` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`payment_id`),
  KEY `invoice_id` (`invoice_id`),
  CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`invoice_id`) REFERENCES `patientinvoice` (`patient_invoice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pharmacybatch`
--

DROP TABLE IF EXISTS `pharmacybatch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pharmacybatch` (
  `batch_id` int NOT NULL AUTO_INCREMENT,
  `item_id` int NOT NULL,
  `supplier_id` int NOT NULL,
  `batch_number` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiry_date` date NOT NULL,
  `selling_unit_price` decimal(10,2) NOT NULL,
  `supply_unit_price` decimal(10,2) NOT NULL,
  `quantity` int NOT NULL,
  PRIMARY KEY (`batch_id`),
  KEY `item_id` (`item_id`),
  KEY `supplier_id` (`supplier_id`),
  CONSTRAINT `pharmacybatch_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `pharmacyitem` (`item_id`),
  CONSTRAINT `pharmacybatch_ibfk_2` FOREIGN KEY (`supplier_id`) REFERENCES `supplier` (`supplier_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pharmacyitem`
--

DROP TABLE IF EXISTS `pharmacyitem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pharmacyitem` (
  `item_id` int NOT NULL AUTO_INCREMENT,
  `item_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `unit` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `prescription`
--

DROP TABLE IF EXISTS `prescription`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `prescription` (
  `prescription_id` int NOT NULL AUTO_INCREMENT,
  `visit_id` int NOT NULL,
  `doctor_id` int NOT NULL,
  `prescribed_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `note` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`prescription_id`),
  KEY `visit_id` (`visit_id`),
  KEY `doctor_id` (`doctor_id`),
  CONSTRAINT `prescription_ibfk_1` FOREIGN KEY (`visit_id`) REFERENCES `visit` (`visit_id`),
  CONSTRAINT `prescription_ibfk_2` FOREIGN KEY (`doctor_id`) REFERENCES `doctor` (`doctor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `prescription_item`
--

DROP TABLE IF EXISTS `prescription_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `prescription_item` (
  `prescription_item_id` int NOT NULL AUTO_INCREMENT,
  `prescription_id` int NOT NULL,
  `item_id` int NOT NULL,
  `quantity` int NOT NULL,
  `dosage` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `usage_instruction` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`prescription_item_id`),
  KEY `prescription_id` (`prescription_id`),
  KEY `item_id` (`item_id`),
  CONSTRAINT `prescription_item_ibfk_1` FOREIGN KEY (`prescription_id`) REFERENCES `prescription` (`prescription_id`),
  CONSTRAINT `prescription_item_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `pharmacyitem` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `role`
--

DROP TABLE IF EXISTS `role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role` (
  `role_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `permission_scope` json NOT NULL,
  PRIMARY KEY (`role_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stockmovement`
--

DROP TABLE IF EXISTS `stockmovement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stockmovement` (
  `movement_id` int NOT NULL AUTO_INCREMENT,
  `batch_id` int NOT NULL,
  `movement_type` enum('IN','OUT') COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int NOT NULL,
  `reference_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_id` int DEFAULT NULL,
  `moved_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`movement_id`),
  KEY `batch_id` (`batch_id`),
  CONSTRAINT `stockmovement_ibfk_1` FOREIGN KEY (`batch_id`) REFERENCES `pharmacybatch` (`batch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `supplier`
--

DROP TABLE IF EXISTS `supplier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `supplier` (
  `supplier_id` int NOT NULL AUTO_INCREMENT,
  `supplier_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`supplier_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `supplierinvoice`
--

DROP TABLE IF EXISTS `supplierinvoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `supplierinvoice` (
  `supplier_invoice_id` int NOT NULL AUTO_INCREMENT,
  `supplier_id` int NOT NULL,
  `batch_id` int NOT NULL,
  `invoice_date` date NOT NULL,
  `total_amount` decimal(15,2) NOT NULL,
  `status` enum('PAID','NOT PAID') COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`supplier_invoice_id`),
  KEY `supplier_id` (`supplier_id`),
  KEY `batch_id` (`batch_id`),
  CONSTRAINT `supplierinvoice_ibfk_1` FOREIGN KEY (`supplier_id`) REFERENCES `supplier` (`supplier_id`),
  CONSTRAINT `supplierinvoice_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `pharmacybatch` (`batch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `timeslot`
--

DROP TABLE IF EXISTS `timeslot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `timeslot` (
  `timeslot_id` int NOT NULL AUTO_INCREMENT,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  PRIMARY KEY (`timeslot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('ACTIVE','LOCKED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `userrole`
--

DROP TABLE IF EXISTS `userrole`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `userrole` (
  `user_role_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `role_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`user_role_id`),
  KEY `user_id` (`user_id`),
  KEY `role_name` (`role_name`),
  CONSTRAINT `userrole_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`),
  CONSTRAINT `userrole_ibfk_2` FOREIGN KEY (`role_name`) REFERENCES `role` (`role_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `visit`
--

DROP TABLE IF EXISTS `visit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `visit` (
  `visit_id` int NOT NULL AUTO_INCREMENT,
  `appointment_id` int NOT NULL,
  `patient_id` int NOT NULL,
  `doctor_id` int NOT NULL,
  `visit_start_time` datetime NOT NULL,
  `visit_end_time` datetime DEFAULT NULL,
  `clinical_note` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`visit_id`),
  KEY `appointment_id` (`appointment_id`),
  KEY `patient_id` (`patient_id`),
  KEY `doctor_id` (`doctor_id`),
  CONSTRAINT `visit_ibfk_1` FOREIGN KEY (`appointment_id`) REFERENCES `appointment` (`appointment_id`),
  CONSTRAINT `visit_ibfk_2` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`),
  CONSTRAINT `visit_ibfk_3` FOREIGN KEY (`doctor_id`) REFERENCES `doctor` (`doctor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `visit_diagnosis`
--

DROP TABLE IF EXISTS `visit_diagnosis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `visit_diagnosis` (
  `visit_diagnosis_id` int NOT NULL AUTO_INCREMENT,
  `visit_id` int NOT NULL,
  `diagnosis_id` int NOT NULL,
  `doctor_id` int NOT NULL,
  `doctor_note` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`visit_diagnosis_id`),
  KEY `visit_id` (`visit_id`),
  KEY `diagnosis_id` (`diagnosis_id`),
  KEY `doctor_id` (`doctor_id`),
  CONSTRAINT `visit_diagnosis_ibfk_1` FOREIGN KEY (`visit_id`) REFERENCES `visit` (`visit_id`),
  CONSTRAINT `visit_diagnosis_ibfk_2` FOREIGN KEY (`diagnosis_id`) REFERENCES `diagnosis` (`diagnosis_id`),
  CONSTRAINT `visit_diagnosis_ibfk_3` FOREIGN KEY (`doctor_id`) REFERENCES `doctor` (`doctor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `visit_service`
--

DROP TABLE IF EXISTS `visit_service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `visit_service` (
  `visit_service_id` int NOT NULL AUTO_INCREMENT,
  `visit_id` int NOT NULL,
  `service_id` int NOT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`visit_service_id`),
  KEY `visit_id` (`visit_id`),
  KEY `service_id` (`service_id`),
  CONSTRAINT `visit_service_ibfk_1` FOREIGN KEY (`visit_id`) REFERENCES `visit` (`visit_id`),
  CONSTRAINT `visit_service_ibfk_2` FOREIGN KEY (`service_id`) REFERENCES `medicalservice` (`service_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-16 18:29:48
