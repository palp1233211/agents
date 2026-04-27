-- 23971 告警信计次表
-- 创建时间: 2026-04-14
-- 作者: lwc

CREATE TABLE `staff_warning_letter_count` (
    `id` INT(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `staff_info_id` INT(11) NOT NULL COMMENT '员工ID',
    `count` INT(11) NOT NULL DEFAULT 0 COMMENT '警告信计次',
    `detail_json` LONGTEXT NOT NULL COMMENT '计次明细JSON字符串',
    `month` VARCHAR(7) NOT NULL COMMENT '汇总月份 YYYY-MM',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_staff_month` (`staff_info_id`, `month`),
    KEY `idx_month` (`month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='员工警告信计次表';