-- I have used my prev HW House Auction database
--creating database with this command
create DATABASE auction_db;
\c auction_db
-- i searched and this makes database switch same as USE auction_db in mssql. but i switchet manually
-- Ensure the auction schema exists
--DROP SCHEMA IF EXISTS auction CASCADE;
--creating new schema
CREATE SCHEMA IF NOT EXISTS auction;

-- Address Table
CREATE TABLE IF NOT EXISTS auction.Address (
    address_id SERIAL PRIMARY KEY,
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    zip_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    CONSTRAINT unique_address UNIQUE (street_address, city, state, zip_code) --this columns must be unique to avoid dublicates
);

-- Bidder Table with Constraints
CREATE TABLE IF NOT EXISTS auction.Bidder (
    bidder_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE, -- Enforcing uniqueness for email
    phone_number VARCHAR(20) NOT NULL,
    address_id INT NOT NULL,
    CONSTRAINT fk_bidder_address FOREIGN KEY (address_id) REFERENCES auction.Address(address_id) ON DELETE CASCADE,
    CONSTRAINT chk_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'), --  valid email format
    CONSTRAINT chk_bidder_phone CHECK (phone_number ~ '^\+?[0-9]+$') --  phone number is numeric (allows optional "+")
);

-- Auctioneer Table with Constraints
CREATE TABLE IF NOT EXISTS auction.Auctioneer (
    auctioneer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE, 
    phone_number VARCHAR(15) NOT NULL,
    CONSTRAINT chk_auctioneer_phone CHECK (phone_number ~ '^\+?[0-9]+$') 
);

-- Auction Table with Constraints
CREATE TABLE IF NOT EXISTS auction.Auction (
    auction_id SERIAL PRIMARY KEY,
    auction_name VARCHAR(255) NOT NULL,
    auction_date TIMESTAMP NOT NULL CHECK (auction_date > '2000-01-01'),
    auctioneer_id INT NOT NULL,
    CONSTRAINT fk_auction_auctioneer FOREIGN KEY (auctioneer_id) REFERENCES auction.Auctioneer(auctioneer_id) ON DELETE CASCADE,
	CONSTRAINT uq_auction_name_date_auctioneer UNIQUE (auction_name, auction_date, auctioneer_id)
 );

-- Category Table with Constraints
CREATE TABLE IF NOT EXISTS auction.Category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE -- enforcing uniqueness for category name
);

-- Item Table with Constraints
CREATE TABLE IF NOT EXISTS auction.Item (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    starting_bid DECIMAL(10,2) NOT NULL CHECK (starting_bid >= 0), --  starting bid is not negative
    category_id INT NOT NULL,
    CONSTRAINT fk_item_category FOREIGN KEY (category_id) REFERENCES auction.Category(category_id) ON DELETE cascade,
    CONSTRAINT uq_item_name_category UNIQUE (item_name, category_id)
);

-- Auction_Item Table (Junction Table) with Constraints
CREATE TABLE IF NOT EXISTS auction.Auction_item (
    auction_id INT NOT NULL,
    item_id INT NOT NULL,
    PRIMARY KEY (auction_id, item_id),
    CONSTRAINT fk_auction_item_auction FOREIGN KEY (auction_id) REFERENCES auction.Auction(auction_id) ON DELETE CASCADE,
    CONSTRAINT fk_auction_item_item FOREIGN KEY (item_id) REFERENCES auction.Item(item_id) ON DELETE CASCADE
);

-- Auctioneer_Item Table (Junction Table) with Constraints
CREATE TABLE IF NOT EXISTS auction.Auctioneer_item (
    auctioneer_id INT NOT NULL,
    item_id INT PRIMARY KEY,
    CONSTRAINT fk_auctioneer_item_auctioneer FOREIGN KEY (auctioneer_id) REFERENCES auction.Auctioneer(auctioneer_id) ON DELETE CASCADE,
    CONSTRAINT fk_auctioneer_item_item FOREIGN KEY (item_id) REFERENCES auction.Item(item_id) ON DELETE CASCADE
);

-- Bid Table with Constraints
CREATE TABLE IF NOT EXISTS auction.Bid (
    bid_id SERIAL PRIMARY KEY,
    bidder_id INT NOT NULL,
    item_id INT NOT NULL,
    bid_amount DECIMAL(10,2) NOT NULL CHECK (bid_amount >= 0), --  bid amount is not negative
    bid_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bid_bidder FOREIGN KEY (bidder_id) REFERENCES auction.Bidder(bidder_id) ON DELETE CASCADE,
    CONSTRAINT fk_bid_item FOREIGN KEY (item_id) REFERENCES auction.Item(item_id) ON DELETE CASCADE,
    CONSTRAINT uq_bidder_item_amount UNIQUE (bidder_id, item_id, bid_amount)
);

-- Payment Table with Constraints
CREATE TABLE IF NOT EXISTS auction.Payment (
    payment_id SERIAL PRIMARY KEY,
    bidder_id INT NOT NULL,
    auction_id INT NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL CHECK (payment_amount >= 0), -- Ensuring payment amount is not negative
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_status VARCHAR(50) NOT NULL DEFAULT 'Pending' CHECK (payment_status IN ('Pending', 'Completed', 'Failed')), -- Enforcing specific status values
    CONSTRAINT fk_payment_bidder FOREIGN KEY (bidder_id) REFERENCES auction.Bidder(bidder_id) ON DELETE CASCADE,
    CONSTRAINT fk_payment_auction FOREIGN KEY (auction_id) REFERENCES auction.Auction(auction_id) ON DELETE cascade,
    CONSTRAINT uq_bidder_auction UNIQUE (bidder_id, auction_id)
);


-- Insert data into Address
INSERT INTO auction.Address (street_address, city, state, zip_code, country) VALUES
('123 Main St', 'New York', 'NY', '10001', 'USA'),
('456 Elm St', 'Los Angeles', 'CA', '90001', 'USA'),
('789 Maple Ave', 'Chicago', 'IL', '60601', 'USA'),
('101 Oak St', 'Houston', 'TX', '77001', 'USA'),
('202 Pine St', 'Phoenix', 'AZ', '85001', 'USA'),
('303 Cedar Ave', 'Philadelphia', 'PA', '19101', 'USA'),
('404 Birch Rd', 'San Antonio', 'TX', '78201', 'USA'),
('505 Spruce Ln', 'San Diego', 'CA', '92101', 'USA'),
('606 Walnut Dr', 'Dallas', 'TX', '75201', 'USA'),
('707 Cherry St', 'San Jose', 'CA', '95101', 'USA'),
('808 Peach Blvd', 'Austin', 'TX', '73301', 'USA'),
('909 Fig St', 'San Francisco', 'CA', '94101', 'USA'),
('1010 Olive Ct', 'Seattle', 'WA', '98101', 'USA'),
('1111 Plum Dr', 'Denver', 'CO', '80201', 'USA'),
('1212 Mango Rd', 'Miami', 'FL', '33101', 'USA'),
('1313 Lemon Ln', 'Atlanta', 'GA', '30301', 'USA'),
('1414 Grape St', 'Boston', 'MA', '02101', 'USA'),
('1515 Berry Blvd', 'Las Vegas', 'NV', '89101', 'USA'),
('1616 Apricot Ave', 'Portland', 'OR', '97201', 'USA'),
('1717 Melon Ct', 'Washington', 'DC', '20001', 'USA')
ON CONFLICT (street_address, city, state, zip_code) DO NOTHING;

-- Insert data into Bidder
INSERT INTO auction.Bidder (first_name, last_name, email, phone_number, address_id) VALUES
('John', 'Doe', 'john.doe@example.com', '+1234567890', 1),
('Jane', 'Smith', 'jane.smith@example.com', '+1987654321', 2),
('Michael', 'Brown', 'michael.brown@example.com', '+1345678901', 3),
('Emily', 'Davis', 'emily.davis@example.com', '+1478901234', 4),
('Daniel', 'Martinez', 'daniel.martinez@example.com', '+1567890123', 5),
('Sophia', 'Anderson', 'sophia.anderson@example.com', '+1678901234', 6),
('Matthew', 'Clark', 'matthew.clark@example.com', '+1789012345', 7),
('Olivia', 'Rodriguez', 'olivia.rodriguez@example.com', '+1890123456', 8),
('James', 'Wilson', 'james.wilson@example.com', '+1901234567', 9),
('Emma', 'Garcia', 'emma.garcia@example.com', '+2012345678', 10),
('Alexander', 'Lopez', 'alexander.lopez@example.com', '+2123456789', 11),
('Ava', 'Hernandez', 'ava.hernandez@example.com', '+2234567890', 12),
('Ethan', 'Hall', 'ethan.hall@example.com', '+2345678901', 13),
('Isabella', 'Young', 'isabella.young@example.com', '+2456789012', 14),
('William', 'Allen', 'william.allen@example.com', '+2567890123', 15),
('Mia', 'King', 'mia.king@example.com', '+2678901234', 16),
('Benjamin', 'Scott', 'benjamin.scott@example.com', '+2789012345', 17),
('Charlotte', 'Adams', 'charlotte.adams@example.com', '+2890123456', 18),
('Daniel', 'Nelson', 'daniel.nelson@example.com', '+2901234567', 19),
('Grace', 'Baker', 'grace.baker@example.com', '+3012345678', 20)
ON CONFLICT (email) DO NOTHING;

-- Insert data into Auctioneer
INSERT INTO auction.Auctioneer (first_name, last_name, email, phone_number) VALUES
('Thomas', 'Miller', 'thomas.miller@example.com', '+3112345678'),
('Natalie', 'Harris', 'natalie.harris@example.com', '+3223456789'),
('Henry', 'Clark', 'henry.clark@example.com', '+3334567890'),
('Ella', 'Lewis', 'ella.lewis@example.com', '+3445678901'),
('Samuel', 'Robinson', 'samuel.robinson@example.com', '+3556789012'),
('Victoria', 'Walker', 'victoria.walker@example.com', '+3667890123'),
('Joseph', 'Perez', 'joseph.perez@example.com', '+3778901234'),
('Lily', 'Hall', 'lily.hall@example.com', '+3889012345'),
('Lucas', 'Allen', 'lucas.allen@example.com', '+3990123456'),
('Scarlett', 'Young', 'scarlett.young@example.com', '+4001234567'),
('Jack', 'Hernandez', 'jack.hernandez@example.com', '+4112345678'),
('Zoe', 'King', 'zoe.king@example.com', '+4223456789'),
('Andrew', 'Scott', 'andrew.scott@example.com', '+4334567890'),
('Evelyn', 'Adams', 'evelyn.adams@example.com', '+4445678901'),
('Gabriel', 'Nelson', 'gabriel.nelson@example.com', '+4556789012'),
('Chloe', 'Baker', 'chloe.baker@example.com', '+4667890123'),
('Ryan', 'Carter', 'ryan.carter@example.com', '+4778901234'),
('Madison', 'Mitchell', 'madison.mitchell@example.com', '+4889012345'),
('Dylan', 'Perez', 'dylan.perez@example.com', '+4990123456'),
('Hannah', 'Robinson', 'hannah.robinson@example.com', '+5001234567')
ON CONFLICT (email) DO NOTHING;

-- Insert data into Auction
INSERT INTO auction.Auction (auction_name, auction_date, auctioneer_id) VALUES
('Classic Car Auction', '2024-06-10 14:00:00', 1),
('Antique Furniture Sale', '2024-06-12 15:30:00', 2),
('Fine Art Exhibition', '2024-06-15 17:00:00', 3),
('Jewelry Auction', '2024-06-20 12:00:00', 4),
('Rare Book Collection', '2024-06-25 10:00:00', 5),
('Vintage Wine Auction', '2024-07-01 18:00:00', 6),
('Real Estate Bidding', '2024-07-05 11:00:00', 7),
('Sports Memorabilia Sale', '2024-07-10 16:00:00', 8),
('Luxury Watch Auction', '2024-07-15 13:00:00', 9),
('Classic Motorcycle Auction', '2024-07-20 14:30:00', 10),
('Electronics Clearance', '2024-07-25 19:00:00', 11),
('Comic Book Collection', '2024-08-01 15:00:00', 12),
('High-End Fashion Sale', '2024-08-05 12:30:00', 13),
('Coin and Currency Auction', '2024-08-10 16:30:00', 14),
('Industrial Equipment Sale', '2024-08-15 09:00:00', 15),
('Luxury Real Estate Auction', '2024-08-20 18:00:00', 16),
('Antique Weaponry Sale', '2024-08-25 14:00:00', 17),
('Retro Video Game Auction', '2024-09-01 13:30:00', 18),
('Designer Handbag Sale', '2024-09-05 17:00:00', 19),
('Exclusive Sneaker Auction', '2024-09-10 16:00:00', 20)
ON CONFLICT (auction_name, auction_date, auctioneer_id) DO NOTHING;

-- Insert data into Category
INSERT INTO auction.Category (category_name) VALUES
('Automobiles'),
('Furniture'),
('Fine Art'),
('Jewelry'),
('Books'),
('Wine & Spirits'),
('Real Estate'),
('Sports Memorabilia'),
('Luxury Watches'),
('Motorcycles'),
('Electronics'),
('Comics & Collectibles'),
('Fashion'),
('Coins & Currency'),
('Industrial Equipment'),
('Luxury Homes'),
('Antique Weapons'),
('Video Games'),
('Designer Handbags'),
('Sneakers')
ON CONFLICT (category_name) DO NOTHING;

-- Insert data into Item
INSERT INTO auction.Item (item_name, description, starting_bid, category_id) VALUES
('Vintage Ford Mustang', 'A 1967 Ford Mustang in mint condition.', 25000.00, 1),
('Antique Oak Dining Table', 'Handcrafted 18th-century oak dining table.', 1500.00, 2),
('Renaissance Oil Painting', 'A rare 16th-century oil painting.', 50000.00, 3),
('Diamond Engagement Ring', 'Platinum band with a 2-carat diamond.', 7000.00, 4),
('First Edition Shakespeare', 'A rare first edition of Shakespeare’s works.', 12000.00, 5),
('Château Margaux 1990', 'A rare bottle of vintage wine.', 4000.00, 6),
('Beachfront Villa', 'Luxury villa with ocean views.', 750000.00, 7),
('Signed Michael Jordan Jersey', 'Authentic jersey signed by Michael Jordan.', 2000.00, 8),
('Rolex Submariner', 'Classic Rolex Submariner in excellent condition.', 12000.00, 9),
('Harley-Davidson 2020', 'Fully loaded 2020 Harley-Davidson Softail.', 18000.00, 10),
('MacBook Pro 2023', 'Latest model MacBook Pro with M2 chip.', 2000.00, 11),
('Spider-Man #1 Comic', 'Original first edition of Spider-Man #1.', 5000.00, 12),
('Gucci Leather Jacket', 'Limited edition Gucci leather jacket.', 1500.00, 13),
('Gold Krugerrand Coin', 'One-ounce gold coin from South Africa.', 2000.00, 14),
('Industrial Forklift', 'Heavy-duty forklift for warehouse use.', 25000.00, 15),
('Modern Mansion', '10-bedroom modern mansion with pool.', 2500000.00, 16),
('Samurai Katana', 'Authentic 16th-century samurai katana.', 15000.00, 17),
('Nintendo 64 Console', 'Classic Nintendo 64 in working condition.', 400.00, 18),
('Louis Vuitton Handbag', 'Luxury handbag from the latest collection.', 2500.00, 19),
('Rare Air Jordans', 'Limited edition Air Jordan 1 sneakers.', 1000.00, 20)
ON CONFLICT (item_name, category_id) DO NOTHING;

-- Insert data into Auction_Item (linking auctions to items)
INSERT INTO auction.Auction_item (auction_id, item_id) VALUES
(1, 1), (2, 2), (3, 3), (4, 4), (5, 5),
(6, 6), (7, 7), (8, 8), (9, 9), (10, 10),
(11, 11), (12, 12), (13, 13), (14, 14), (15, 15),
(16, 16), (17, 17), (18, 18), (19, 19), (20, 20)
ON CONFLICT (auction_id, item_id) DO NOTHING;

-- Insert data into Auctioneer_Item (assigning auctioneers to items)
INSERT INTO auction.Auctioneer_item (auctioneer_id, item_id) VALUES
(1, 1), (2, 2), (3, 3), (4, 4), (5, 5),
(6, 6), (7, 7), (8, 8), (9, 9), (10, 10),
(11, 11), (12, 12), (13, 13), (14, 14), (15, 15),
(16, 16), (17, 17), (18, 18), (19, 19), (20, 20)
ON CONFLICT (item_id) DO NOTHING;

-- Insert data into Bid (bidders placing bids on items)
INSERT INTO auction.Bid (bidder_id, item_id, bid_amount, bid_time) VALUES
(1, 1, 26000.00, '2024-06-10 14:30:00'),
(2, 2, 1600.00, '2024-06-12 16:00:00'),
(3, 3, 52000.00, '2024-06-15 18:00:00'),
(4, 4, 7500.00, '2024-06-20 12:30:00'),
(5, 5, 12500.00, '2024-06-25 10:30:00'),
(6, 6, 4200.00, '2024-07-01 19:00:00'),
(7, 7, 760000.00, '2024-07-05 11:30:00'),
(8, 8, 2500.00, '2024-07-10 17:00:00'),
(9, 9, 12500.00, '2024-07-15 14:00:00'),
(10, 10, 19000.00, '2024-07-20 15:00:00'),
(11, 11, 2100.00, '2024-07-25 19:30:00'),
(12, 12, 5200.00, '2024-08-01 16:00:00'),
(13, 13, 1600.00, '2024-08-05 13:00:00'),
(14, 14, 2500.00, '2024-08-10 17:30:00'),
(15, 15, 25500.00, '2024-08-15 10:30:00'),
(16, 16, 2600000.00, '2024-08-20 18:30:00'),
(17, 17, 16000.00, '2024-08-25 14:30:00'),
(18, 18, 500.00, '2024-09-01 14:00:00'),
(19, 19, 2800.00, '2024-09-05 18:00:00'),
(20, 20, 1200.00, '2024-09-10 16:30:00')
ON CONFLICT(bidder_id, item_id, bid_amount) DO NOTHING;

-- Insert data into Payment
INSERT INTO auction.Payment (bidder_id, auction_id, payment_amount, payment_date, payment_status) VALUES
(1, 1, 26000.00, '2024-06-11 10:00:00', 'Completed'),
(2, 2, 1600.00, '2024-06-13 12:00:00', 'Completed'),
(3, 3, 52000.00, '2024-06-16 14:00:00', 'Pending'),
(4, 4, 7500.00, '2024-06-21 11:00:00', 'Completed'),
(5, 5, 12500.00, '2024-06-26 15:00:00', 'Failed'),
(6, 6, 4200.00, '2024-07-02 13:00:00', 'Completed'),
(7, 7, 760000.00, '2024-07-06 12:00:00', 'Completed'),
(8, 8, 2500.00, '2024-07-11 14:00:00', 'Completed'),
(9, 9, 12500.00, '2024-07-16 11:30:00', 'Pending'),
(10, 10, 19000.00, '2024-07-21 10:30:00', 'Completed'),
(11, 11, 2100.00, '2024-07-26 15:30:00', 'Failed'),
(12, 12, 5200.00, '2024-08-02 16:00:00', 'Completed'),
(13, 13, 1600.00, '2024-08-06 13:30:00', 'Pending'),
(14, 14, 2500.00, '2024-08-11 11:00:00', 'Completed'),
(15, 15, 25500.00, '2024-08-16 09:30:00', 'Completed'),
(16, 16, 8900.00, '2024-08-20 14:45:00', 'Completed'),
(17, 17, 3200.00, '2024-08-25 10:00:00', 'Pending'),
(18, 18, 15000.00, '2024-08-28 12:15:00', 'Completed'),
(19, 19, 7100.00, '2024-09-01 11:20:00', 'Failed'),
(20, 20, 4600.00, '2024-09-05 09:50:00', 'Completed');
ON CONFLICT(bidder_id, auction_id) DO NOTHING;


-- add new column record_ts to all table with default value
ALTER TABLE Address
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE auction.Bidder
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE auction.Auctioneer
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE auction.Auction
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE auction.Category
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE auction.Item
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE auction.Auction_item
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE auction.Auctioneer_item
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE auction.Bid
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE auction.Payment
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;


select *
from auction.Address

---ive checked  tables and current date was add
ALTER TABLE auction.Bidder
ADD COLUMN full_name VARCHAR GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED;
-- example of GENERATED ALWAYS AS usage :)
