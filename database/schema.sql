/* ============================================================
   Ember & Code Ducking Adventures
   SQL Server Database Schema
   ============================================================ */

---------------------------------------------------------------
-- UPDATED Ducks Table (Full CSV-Compatible Schema)
---------------------------------------------------------------
CREATE TABLE dbo.Ducks (
    Duck_ID INT IDENTITY(1,1) PRIMARY KEY,
    User_ID VARCHAR(100) NULL,
    Duck_Type VARCHAR(100) NULL,
    Duck_Name VARCHAR(200) NOT NULL,
    Duck_Bio VARCHAR(MAX) NULL,
    Duck_Status VARCHAR(100) NOT NULL DEFAULT 'Active',
    Photo_URL VARCHAR(500) NULL,
    Date_Given DATE NULL,
    Location_Given VARCHAR(250) NULL,
    Giver_User_ID VARCHAR(100) NULL,
    Receiver_User_ID VARCHAR(100) NULL,
    QR_Code_ID VARCHAR(250) NULL,
    Last_Updated DATETIME NULL,
    Created_At DATETIME NOT NULL DEFAULT GETDATE()
);

---------------------------------------------------------------
-- 2. Users Table
---------------------------------------------------------------
CREATE TABLE dbo.Users (
    User_ID INT IDENTITY(1,1) PRIMARY KEY,
    First_Name VARCHAR(100) NOT NULL,
    Last_Name VARCHAR(100) NOT NULL,
    Email VARCHAR(250) NOT NULL UNIQUE,
    Password_Hash VARCHAR(250) NOT NULL,
    Join_Date DATETIME NOT NULL DEFAULT GETDATE()
);

---------------------------------------------------------------
-- 3. Duck Journey Table
---------------------------------------------------------------
CREATE TABLE dbo.Duck_Journey (
    Journey_ID INT IDENTITY(1,1) PRIMARY KEY,
    Duck_ID INT NOT NULL,
    User_ID INT NULL,
    Event_Type VARCHAR(100) NOT NULL,
    Event_Name VARCHAR(250) NULL,
    Event_Location VARCHAR(250) NULL,
    Event_Date DATE NULL,
    Photo_URL VARCHAR(500) NULL,
    Event_Notes VARCHAR(MAX) NULL,
    Created_At DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_DuckJourney_Duck
        FOREIGN KEY (Duck_ID) REFERENCES dbo.Ducks(Duck_ID),

    CONSTRAINT FK_DuckJourney_User
        FOREIGN KEY (User_ID) REFERENCES dbo.Users(User_ID)
);

---------------------------------------------------------------
-- 4. Duck Achievement Table
---------------------------------------------------------------
CREATE TABLE dbo.Duck_Achievement (
    Achievement_ID INT IDENTITY(1,1) PRIMARY KEY,
    Duck_ID INT NOT NULL,
    Achievement_Name VARCHAR(250) NOT NULL,
    Achievement_Description VARCHAR(MAX) NULL,
    Achievement_Date DATE NULL,
    Created_At DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_DuckAchievement_Duck
        FOREIGN KEY (Duck_ID) REFERENCES dbo.Ducks(Duck_ID)
);

---------------------------------------------------------------
-- 5. Helpful Indexes
---------------------------------------------------------------
CREATE INDEX IX_DuckJourney_DuckID ON dbo.Duck_Journey(Duck_ID);
CREATE INDEX IX_DuckJourney_UserID ON dbo.Duck_Journey(User_ID);
CREATE INDEX IX_DuckAchievement_DuckID ON dbo.Duck_Achievement(Duck_ID);

---------------------------------------------------------------
-- 6. Optional: Status Lookup Table (Future Enhancement)
---------------------------------------------------------------
-- CREATE TABLE dbo.Duck_Status (
--     Status_ID INT IDENTITY(1,1) PRIMARY KEY,
--     Status_Name VARCHAR(100) NOT NULL UNIQUE
-- );
