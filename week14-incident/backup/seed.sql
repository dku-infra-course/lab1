-- 실측 전
-- 샘플 데이터. 각 행에 시각(created_at)이 있어 RPO(마지막 백업 이후 잃은 구간)를 잴 수 있다.
CREATE DATABASE IF NOT EXISTS shop;
USE shop;

CREATE TABLE IF NOT EXISTS orders (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  item       VARCHAR(50) NOT NULL,
  qty        INT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
);

INSERT INTO orders (item, qty) VALUES
  ('notebook', 1), ('pen', 10), ('monitor', 1), ('keyboard', 2), ('mouse', 3),
  ('usb-cable', 5), ('webcam', 1), ('headset', 2), ('desk-lamp', 1), ('stand', 1);

SELECT COUNT(*) AS rows_total, MAX(created_at) AS last_row_time FROM orders;
