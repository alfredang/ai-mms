-- Add profile fields to admin_user table
ALTER TABLE admin_user
    ADD COLUMN tel VARCHAR(20) DEFAULT NULL AFTER email,
    ADD COLUMN gender VARCHAR(10) DEFAULT NULL AFTER tel,
    ADD COLUMN race VARCHAR(50) DEFAULT NULL AFTER gender,
    ADD COLUMN dob DATE DEFAULT NULL AFTER race,
    ADD COLUMN nric_fin VARCHAR(20) DEFAULT NULL AFTER dob,
    ADD COLUMN linkedin_url VARCHAR(255) DEFAULT NULL AFTER nric_fin,
    ADD COLUMN profile_image VARCHAR(255) DEFAULT NULL AFTER linkedin_url;
