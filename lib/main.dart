import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:altstack/TaskDisplay.dart'; // Importing necessary packages and files
import 'package:altstack/Database/profile.dart';
import 'package:altstack/Database/database_helper.dart';
import 'package:altstack/Tasks/Tasks.dart';
import 'package:altstack/Tasks/Tasks_database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize profile database
  final profileDatabase = await _initializeProfileDatabase();

  // Initialize class event database
  final classEventDatabase = await _initializeClassEventDatabase();

  runApp(MyApp(profileDatabase: profileDatabase, classEventDatabase: classEventDatabase));
}

// Function to initialize the profile database
Future<Database> _initializeProfileDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  final path = join(directory.path, 'profiles_database.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE profiles(id INTEGER PRIMARY KEY, name TEXT, imagePath TEXT)",
      );
    },
  ).then((db) async {
    await _initializeProfiles(db);
    return db;
  });
}

// Function to initialize profile data
Future<void> _initializeProfiles(Database db) async {
  final List<Profile> profiles = [
    Profile(id: 1, name: 'Chandu', imagePath: 'assets/chandu.jpg'),
    // Add more profiles if needed
  ];

  // Check if profiles already exist
  final List<Map<String, dynamic>> existingProfiles = await db.query('profiles');
  if (existingProfiles.isEmpty) {
    // Insert profiles into the database if it's empty
    final batch = db.batch();
    for (var profile in profiles) {
      batch.insert('profiles', profile.toMap());
    }
    await batch.commit(noResult: true);
  }
}

// Function to initialize the class event database
Future<Database> _initializeClassEventDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  final path = join(directory.path, 'task_events_database.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE task_events(id INTEGER PRIMARY KEY, task_name TEXT, description TEXT, is_completed TEXT DEFAULT 'NO')",
      );
    },
  ).then((db) async {
    await _initializeClassEvents(db);
    return db;
  });
}

// Function to initialize class event data
Future<void> _initializeClassEvents(Database db) async {
  final List<TaskEvent> classEvents = [
    TaskEvent(taskName: 'Task 1', description: 'Click On Add Task'),
    // Add more initial data if needed
  ];

  // Check if class events already exist
  final List<Map<String, dynamic>> existingClassEvents = await db.query('task_events');
  if (existingClassEvents.isEmpty) {
    // Insert class events into the database if it's empty
    final batch = db.batch();
    for (final event in classEvents) {
      batch.insert('task_events', event.toMap());
    }
    await batch.commit(noResult: true);
  }
}

// MyApp widget
class MyApp extends StatelessWidget {
  final Database profileDatabase;
  final Database classEventDatabase;

  MyApp({required this.profileDatabase, required this.classEventDatabase});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(profileDatabase: profileDatabase, classEventDatabase: classEventDatabase),
    );
  }
}

// MyHomePage widget
class MyHomePage extends StatefulWidget {
  final Database profileDatabase;
  final Database classEventDatabase;

  MyHomePage({required this.profileDatabase, required this.classEventDatabase});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// State class for MyHomePage
class _MyHomePageState extends State<MyHomePage> {
  Profile? _selectedProfile;
  File? _selectedImageFile; // Add this line to declare the selected image file
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  TextEditingController _profileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSelectedProfile();
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    super.dispose();
  }

  // Function to load the selected profile from SharedPreferences
  Future<void> _loadSelectedProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? selectedProfileId = prefs.getInt('selected_profile_id');
    if (selectedProfileId != null) {
      final Profile selectedProfile = await _databaseHelper.getProfile(selectedProfileId);
      setState(() {
        _selectedProfile = selectedProfile;
      });
    }
  }

  // Function to handle click on camera icon to select image
  void _handleCameraIconClick() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  // Function to show profile creation dialog
  void _showProfileCreationDialog(BuildContext context) async {
    // Load the existing selected profile
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? selectedProfileId = prefs.getInt('selected_profile_id');
    Profile? existingProfile;
    if (selectedProfileId != null) {
      existingProfile = await _databaseHelper.getProfile(selectedProfileId);
    }

    // Initialize the text field controller with existing profile name
    _profileNameController.text = existingProfile?.name ?? '';

    // Initialize the selected image file with existing profile image
    final String? existingImagePath = existingProfile?.imagePath;
    if (existingImagePath != null && existingImagePath.isNotEmpty) {
      setState(() {
        _selectedImageFile = File(existingImagePath);
      });
    }

    // Show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _handleCameraIconClick,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: _selectedImageFile != null
                          ? CircleAvatar(
                        backgroundImage: FileImage(_selectedImageFile!),
                      )
                          : Image.asset(
                        'assets/gallery.png',
                        width: 30,
                        height: 30,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: _profileNameController,
                      decoration: InputDecoration(
                        labelText: 'Enter your name',
                        counterText: '',
                      ),
                      maxLength: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                _saveProfile(
                  _profileNameController.text,
                  _selectedImageFile ?? File('path_to_default_image'),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to save a new profile
  Future<void> _saveProfile(String profileName, File imageFile) async {
    if (profileName.isNotEmpty) {
      String imagePath = await _saveImageToLocalStorage(imageFile);
      Profile newProfile = Profile(
        name: profileName,
        imagePath: imagePath,
      );
      int profileId = await _databaseHelper.insertProfile(newProfile);
      Profile insertedProfile = await _databaseHelper.getProfile(profileId);
      setState(() {
        _selectedProfile = insertedProfile;
      });
      _saveSelectedProfile(profileId);
    }
  }

  // Function to save image to local storage
  Future<String> _saveImageToLocalStorage(File imageFile) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String imagePath = join(documentsDirectory.path, 'profile_images');
    if (!(await Directory(imagePath).exists())) {
      await Directory(imagePath).create(recursive: true);
    }
    String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
    String filePath = join(imagePath, fileName);
    await imageFile.copy(filePath);
    return filePath;
  }

  // Function to save the selected profile ID to SharedPreferences
  Future<void> _saveSelectedProfile(int profileId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_profile_id', profileId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedProfile != null
            ? GestureDetector(
          onTap: () {
            _showProfileCreationDialog(context);
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundImage: FileImage(File(_selectedProfile!.imagePath)),
              ),
              SizedBox(width: 20),
              Text(
                _selectedProfile!.name,
                style: TextStyle(
                  fontFamily: 'ArefRuqaaInk',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )
            : Text('Profile Selection'),
        actions: [],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/OIP.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: _selectedProfile != null
                ? TaskScreen()
                : ElevatedButton(
              onPressed: () {
                _showProfileCreationDialog(context);
              },
              child: Text('Create Profile'),
            ),
          ),
        ],
      ),
    );
  }

  // Function to show popup menu
  void _showPopupMenu(BuildContext context) {
    final RenderBox overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final Offset offset = Offset(0.0, overlay.size.height);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 75, 25, 0),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          child: Text('Change Profile'),
          value: 'change_profile',
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value == 'change_profile') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskScreen(),
          ),
        ).then((selectedProfile) {
          if (selectedProfile != null) {
            setState(() {
              _selectedProfile = selectedProfile;
            });
            _saveSelectedProfile(selectedProfile.id);
          }
        });
      }
    });
  }
}
