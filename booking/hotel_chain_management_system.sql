CREATE DATABASE online_book_publishing_sales_platform;

use online_book_publishing_sales_platform;

CREATE TABLE Publisher (
	PublisherID INT PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	ContactDetails VARCHAR(255) 
); 

CREATE TABLE Book (
	BookID INT PRIMARY KEY,
	Title VARCHAR(200) NOT NULL,
	ISBN VARCHAR(20) NOT NULL,
	Edition INT NOT NULL,
	PublicationYear INT,
	Price DECIMAL(10, 2),
    PublisherID INT,
	FOREIGN KEY (PublisherID) REFERENCES Publisher(PublisherID)
);

CREATE TABLE Genre (
	GenreID INT PRIMARY KEY,
    GenreName VARCHAR(100) NOT NULL
);

CREATE TABLE BookGenre (
	BookId INT,
    GenreId INT,
    PRIMARY KEY (BookId, GenreId),
    FOREIGN KEY (BookId) REFERENCES Book(BookID),
    FOREIGN KEY (GenreId) REFERENCES Genre(GenreID)
);

CREATE TABLE Author (
	AuthouID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Biography TEXT
);

CREATE TABLE BookAuthor (
	BookID INT,
    AuthorID INT,
    PRIMARY KEY (BookID, AuthorID),
    FOREIGN KEY (BookID) REFERENCES Book(BookID),
    FOREIGN KEY (AuthorID) REFERENCES Author(AuthorID)
);

CREATE TABLE Customer (
	CustomerID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL
);

CREATE TABLE Address (
	AddressID INT PRIMARY KEY,
    CustomerID INT,
    Street VARCHAR(100),
    City VARCHAR(100),
    State VARCHAR(100),
    Country VARCHAR(100),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

CREATE TABLE Whishlist (
	CustomerID INT,
    BookID INT,
    PRIMARY KEY (CustomerID, BookID),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (BookID) REFERENCES Book(BookID)
);

CREATE TABLE Orderr (
	OrderID INT PRIMARY KEY,
    OrderDate DATE NOT NULL,
    CustomerID INT,
    PaymentDetails VARCHAR(255),
    ShipmentStatus VARCHAR(50),
    ShipmentAddressID INT,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (ShippingAddressID) REFERENCES Address(AddressID)
);


CREATE TABLE Order_Book (
	OrderItemID INT PRIMARY KEY,
    OrderID INT,
    BookID INT,
    Quantity INT NOT NULL,
    ItemDiscount DECIMAL(5,2),
    FOREIGN KEY (OrderID) REFERENCES Orderr(OrderID),
    FOREIGN KEY (BookID) REFERENCES Book(BookID)
);


INSERT INTO Publisher (PublisherID, Name, ContactDetails) VALUES
(1, 'Penguin Random House', 'contact@penguinrandomhouse.com'),
(2, 'HarperCollins', 'info@harpercollins.com'),
(3, 'Macmillan Publishers', 'support@macmillan.com'),
(4, 'Simon & Schuster', 'help@simonandschuster.com'),
(5, 'Hachette Livre', 'contact@hachette.com'),
(6, 'Scholastic', 'info@scholastic.com'),
(7, 'Pearson', 'support@pearson.com'),
(8, 'Oxford University Press', 'contact@oup.com'),
(9, 'Wiley', 'info@wiley.com'),
(10, 'Cambridge University Press', 'support@cambridge.org');

-- Insert data into Book table
INSERT INTO Book (BookID, Title, ISBN, Edition, PublicationYear, Price, PublisherID) VALUES
(1, 'To Kill a Mockingbird', '9780060935467', 1, 1960, 15.99, 2),
(2, '1984', '9780451524935', 1, 1949, 12.99, 1),
(3, 'The Great Gatsby', '9780743273565', 1, 1925, 10.99, 4),
(4, 'Pride and Prejudice', '9780141439518', 2, 1813, 9.99, 8),
(5, 'Moby-Dick', '9780142437247', 1, 1851, 11.99, 8),
(6, 'The Catcher in the Rye', '9780316769488', 1, 1951, 8.99, 7),
(7, 'Jane Eyre', '9780141441146', 3, 1847, 10.49, 8),
(8, 'Wuthering Heights', '9780141439556', 2, 1847, 9.49, 8),
(9, 'Frankenstein', '9780486282114', 1, 1818, 6.99, 10),
(10, 'Animal Farm', '9780451526342', 1, 1945, 7.99, 1);

-- Insert data into Genre table
INSERT INTO Genre (GenreID, GenreName) VALUES
(1, 'Fiction'),
(2, 'Science Fiction'),
(3, 'Fantasy'),
(4, 'Romance'),
(5, 'Historical'),
(6, 'Mystery'),
(7, 'Thriller'),
(8, 'Horror'),
(9, 'Biography'),
(10, 'Philosophy');

-- Insert data into BookGenre table
INSERT INTO BookGenre (BookID, GenreID) VALUES
(1, 1),
(2, 1),
(3, 1),
(4, 4),
(5, 5),
(6, 1),
(7, 4),
(8, 4),
(9, 8),
(10, 1);

-- Insert data into Author table
INSERT INTO Author (AuthouID, Name, Biography) VALUES
(1, 'Harper Lee', 'American novelist known for To Kill a Mockingbird.'),
(2, 'George Orwell', 'British author and journalist, famous for 1984 and Animal Farm.'),
(3, 'F. Scott Fitzgerald', 'American novelist and short story writer.'),
(4, 'Jane Austen', 'English novelist known for romantic fiction.'),
(5, 'Herman Melville', 'American novelist and poet, known for Moby-Dick.'),
(6, 'J.D. Salinger', 'American writer, known for The Catcher in the Rye.'),
(7, 'Charlotte Brontë', 'English novelist and poet.'),
(8, 'Emily Brontë', 'English novelist and poet, known for Wuthering Heights.'),
(9, 'Mary Shelley', 'English novelist, known for Frankenstein.'),
(10, 'Aldous Huxley', 'English writer, philosopher, and author of Brave New World.');

-- Insert data into BookAuthor table
INSERT INTO BookAuthor (BookID, AuthorID) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 2);

-- Insert data into Customer table
INSERT INTO Customer (CustomerID, Name) VALUES
(1, 'Alice Johnson'),
(2, 'Bob Smith'),
(3, 'Charlie Brown'),
(4, 'Diana Prince'),
(5, 'Eve Adams'),
(6, 'Frank Castle'),
(7, 'Grace Hopper'),
(8, 'Hank Pym'),
(9, 'Ivy League'),
(10, 'Jack Ryan');

-- Insert data into Address table
INSERT INTO Address (AddressID, CustomerID, Street, City, State, Country) VALUES
(1, 1, '123 Maple Street', 'New York', 'NY', 'USA'),
(2, 2, '456 Oak Avenue', 'Los Angeles', 'CA', 'USA'),
(3, 3, '789 Pine Road', 'Chicago', 'IL', 'USA'),
(4, 4, '101 Birch Blvd', 'Houston', 'TX', 'USA'),
(5, 5, '202 Cedar Lane', 'Phoenix', 'AZ', 'USA'),
(6, 6, '303 Elm Drive', 'Philadelphia', 'PA', 'USA'),
(7, 7, '404 Walnut Way', 'San Antonio', 'TX', 'USA'),
(8, 8, '505 Chestnut Circle', 'San Diego', 'CA', 'USA'),
(9, 9, '606 Spruce Court', 'Dallas', 'TX', 'USA'),
(10, 10, '707 Fir Place', 'San Jose', 'CA', 'USA');

-- Insert data into Whishlist table
INSERT INTO Whishlist (CustomerID, BookID) VALUES
(1, 1),
(1, 2),
(2, 3),
(3, 4),
(4, 5),
(5, 6),
(6, 7),
(7, 8),
(8, 9),
(9, 10);

-- Insert data into Orderr table
INSERT INTO Orderr (OrderID, OrderDate, CustomerID, PaymentDetails, ShipmentStatus, ShipmentAddressID) VALUES
(1, '2023-06-01', 1, 'Credit Card', 'Shipped', 1),
(2, '2023-06-02', 2, 'PayPal', 'Processing', 2),
(3, '2023-06-03', 3, 'Debit Card', 'Delivered', 3),
(4, '2023-06-04', 4, 'Net Banking', 'Shipped', 4),
(5, '2023-06-05', 5, 'Credit Card', 'Processing', 5),
(6, '2023-06-06', 6, 'PayPal', 'Delivered', 6),
(7, '2023-06-07', 7, 'Credit Card', 'Shipped', 7),
(8, '2023-06-08', 8, 'Debit Card', 'Processing', 8),
(9, '2023-06-09', 9, 'Net Banking', 'Delivered', 9),
(10, '2023-06-10', 10, 'Credit Card', 'Shipped', 10);

-- Insert data into Order_Book table
INSERT INTO Order_Book (OrderItemID, OrderID, BookID, Quantity, ItemDiscount) VALUES
(1, 1, 1, 1, 0.00),
(2, 2, 2, 2, 5.00),
(3, 3, 3, 1, 10.00),
(4, 4, 4, 3, 0.00),
(5, 5, 5, 2, 15.00),
(6, 6, 6, 1, 0.00),
(7, 7, 7, 2, 5.00),
(8, 8, 8, 1, 10.00),
(9, 9, 9, 3, 0.00),
(10, 10, 10, 2, 15.00);