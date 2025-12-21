-- =====================================================
-- EXPIRY CHECK EVENT
-- =====================================================
USE hospital_management_system;

DELIMITER $$

SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS e_daily_pharmacy_inventory_check$$

CREATE EVENT e_daily_pharmacy_inventory_check
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 8 HOUR)
DO
BEGIN
    DECLARE v_warning_type_id INT;
    DECLARE v_expired_type_id INT;
    
    -- Get Notification Type IDs
    SELECT notification_type_id INTO v_warning_type_id FROM Notification_Type WHERE type_name = 'STOCK_EXPIRY_WARNING' LIMIT 1;
    
    SET v_expired_type_id = v_warning_type_id;

    -- 1. WARNING: Expiring in the next 24 hours
    INSERT INTO Notification (user_id, notification_type_id, content, is_read)
    SELECT 
        u.user_id, 
        v_warning_type_id, 
        CONCAT('URGENT: Batch ', pb.batch_number, ' for ', pi.item_name, ' expires within 24 hours.'),
        FALSE
    FROM PharmacyBatch pb
    JOIN PharmacyItem pi ON pb.item_id = pi.item_id
    JOIN UserRole ur ON ur.role_name IN ('PHARMACIST', 'ADMIN')
    JOIN Users u ON ur.user_id = u.user_id
    WHERE pb.expiry_date <= DATE_ADD(NOW(), INTERVAL 24 HOUR)
      AND pb.expiry_date > NOW()
      AND pb.quantity > 0;

    -- 2. EXPIRED: Already hit the expiry date
    INSERT INTO Notification (user_id, notification_type_id, content, is_read)
    SELECT 
        u.user_id, 
        v_expired_type_id, 
        CONCAT('EXPIRED: Batch ', pb.batch_number, ' for ', pi.item_name, ' has expired. DO NOT DISPENSE.'),
        FALSE
    FROM PharmacyBatch pb
    JOIN PharmacyItem pi ON pb.item_id = pi.item_id
    JOIN UserRole ur ON ur.role_name IN ('PHARMACIST', 'ADMIN')
    JOIN Users u ON ur.user_id = u.user_id
    WHERE pb.expiry_date <= NOW()
      AND pb.quantity > 0;

END$$

DELIMITER ;