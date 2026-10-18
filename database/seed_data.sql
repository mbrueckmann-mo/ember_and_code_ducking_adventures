/* ============================================================
   Ember & Code Ducking Adventures
   SQL Server Seed Data
   Inserts all ducks from E_and_C_Ducks.csv
   ============================================================ */

---------------------------------------------------------------
-- Ducks Seed Data
---------------------------------------------------------------

INSERT INTO dbo.Ducks (
    Duck_ID,
    User_ID,
    Duck_Type,
    Duck_Name,
    Duck_Bio,
    Duck_Status,
    Photo_URL,
    Date_Given,
    Location_Given,
    Giver_User_ID,
    Receiver_User_ID,
    QR_Code_ID,
    Last_Updated
)
VALUES
(1, 'michael_ec_macfezzed', 'Shriner Duck', 'EC MacFezzed',
 'A dapper duck with a bow tie and Fez, always ready to lead a parade with charm and courage.',
 'Owned',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/EC_MacFezzed_full-226x300.jpg',
 '2024-06-05', 'Moolah Shrine Temple',
 NULL, NULL, NULL, NULL),

(2, NULL, 'Holloween Duck', 'Witchy Waddle',
 'Casts spells and charms every Jeep she rides in.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Witchy_Waddle-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(3, NULL, 'Holloween Duck', 'Bloody Beak Jr',
 'The mischievous heir to the original haunted flock.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Bloody_Beak_Jr-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(4, NULL, 'Holloween Duck', 'Nurse Quackswell',
 'Treats boo-boos and broken spells with spooky care.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Nurse_Quackswell-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(5, NULL, 'Holloween Duck', 'Dr Bone McQuackers',
 'A skeletal scholar who diagnoses Halloween chills.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Dr_Bone_McQuackers-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(6, NULL, 'Holloween Duck', 'Count Waddleton',
 'The suave vampire duck who rules the midnight pond.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Count_Waddleton-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(7, NULL, 'Holloween Duck', 'Boo Quacker Duckkins',
 'Friendly ghost who loves popping out for Jeep scares.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Boo_Quacker_Duckkins-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(8, NULL, 'Holloween Duck', 'Spooky Squashington',
 'A refined pumpkin spirit with impeccable seasonal style.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Spooky_Squashington-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(9, NULL, 'Holloween Duck', 'Dusty McWraps',
 'An ancient mummy duck awakened from the tomb to join your haunted Jeep adventures.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Dusty_McWraps-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(10, NULL, 'Holloween Duck', 'Blackbeak the Haunted',
 'The cursed captain who sails between worlds.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Blackbeak_the_Haunted-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(11, NULL, 'Holloween Duck', 'Ghostbeard the Dread Duckerson',
 'The spectral pirate who commands the Halloween fleet.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Ghostbeard_the_Dread_Duckerson-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(12, NULL, 'Holloween Duck', 'Smiley McLantern',
 'The happiest jack-o-lantern duck in the patch.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Smiley_McLantern-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(13, NULL, 'Holloween Duck', 'Shocky Quackers',
 'The electrifying genius of the flock, stitched together with charm and ready to jolt every Jeep adventure to life.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Shocky_Quackers-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(14, NULL, 'Holloween Duck', 'Arachnquakia',
 'The mysterious web-weaver of the flock, spinning spooky charm wherever her Jeep adventures lead.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Arachnquackia-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(15, NULL, 'Holloween Duck', 'Meow Quacker',
 'The stealthy feline of the flock, prowling Jeep trails with purr-fect precision and a mischievous quack.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Meow_Quacker-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(16, NULL, 'Holloween Duck', 'Dutchess of Duckingham',
 'The elegant noble of the flock, quacking with poise and charm through every Jeep adventure she graces.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Duchess_of_Duckingham-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(17, NULL, 'Holloween Duck', 'Sir Quacks A Scream',
 'The shrieking specter of the pond, haunting Jeep trails with a chilling quack that echoes through the night.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Sir_Quacks_A_Scream-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(18, NULL, 'Holloween Duck', 'Phantom Plucker',
 'The ghostly trickster of the flock, gliding through Jeep nights with a haunting quack and a mischievous grin.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Phantom_Plucker-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(19, NULL, 'Holloween Duck', 'Lil Fang Von Duckstein',
 'A charming little vampire who flutters through Jeep nights with bite-sized mischief.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Lil_Fang_Von_Duckstein-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(20, NULL, 'Holloween Duck', 'Wraptor Quack A Tut',
 'Ancient mummy duck awakened for Jeep adventures.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Wraptor_Quack_A_Tut-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(21, NULL, 'Holloween Duck', 'Happy Hauntlet',
 'A cheerful pumpkin spirit who glows brighter than any jack-o-lantern on the trail.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Happy_Hauntlet-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(22, NULL, 'Holloween Duck', 'Darkwing Mowler',
 'The punk-rock phantom who prowls moonlit roads with rebellious Halloween energy.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Darkwing_Mowler-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(23, NULL, 'Holloween Duck', 'Mortimer the Reaper',
 'The solemn scythe-bearing collector of lost ducks and guardian of spooky order.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Mortimer_The_Reaper-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL),

(24, NULL, 'Holloween Duck', 'Sister Beaktrice the Unholy',
 'A haunting nun who blesses the flock with eerie hymns and unholy charm.',
 'In House',
 'https://charredoakdigitaldevelopment.com/wp-content/uploads/2026/10/Sister_Beaktric_the_Unholy-226x300.jpg',
 NULL, NULL,
 'michael_ec_macfezzed', NULL, NULL, NULL);
