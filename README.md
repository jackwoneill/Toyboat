# Toyboat
Cloud Music App. For use with Toyboat_Backend. Allows for downloading to local device for offline play. Custom backend avoids iCloud, uses own file storage/serving.
Not much has been done in terms of the visual aspect of the application, at the current state it is a working build of a music playing application with a custom web backend that does not require iCloud to use.
Utilizes Realm for persistent data storage.


# Features 
Loads audio files both from local device(as would find in normal music app) and from hosted backend.
Custom playlist creation
Swipe on object to store locally or remove from local storage
Custom expanding menu, as visible in the Artists View Controller
Shuffled playing

# Usage
To use, simply upload songs to the web backend and allow it to run @ localhost on port 3000. 
Create an account on the web backend with loging a@a.com//password. Or replace in appdelegate to your own.
As it is not currently set up for user switching, to test it you will need to change the directory that it pulls song files from.
To do this, navigate to the /public/directories folder in the backend, and copy the directory name, the current directory is a162ece85e7b1b03128f138dfc63a036196c07b6c7e9ea54.
This will need to be changed wherever you find this directory in the project.

# Todo
User login/user handling. Not very difficult, web backend is already set up for it
A lot in the design area. The functionality works fine, however design elements such as buttons, improved table design, etc.

