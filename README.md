# Find My Dog - Honours Project

Mobile application developed using the Flutter framework and makes use of Firebase, GeoFlutterFire and Tensorflow. App can create dog posts to report Lost, Stolen and Found dogs and send notifications to appropriate users. Application makes use of Machine Learning in 2 ways, It can use Image classification to classify a dog breed to aid with user input as well as Optical Character Recognition (OCR) to aid in inputing emails and phone numbers.

## Useful Links

[Image classification Model](https://drive.google.com/file/d/1BHwAt8NTMD5eItCuXhgNuvby4XBU9bBe/view?usp=sharing)

[NextJS web application](https://github.com/DuffyCorp/findMyDogWeb)

[Python Code for creating model](https://github.com/DuffyCorp/FindMyDogModelMaker)

## Getting Started

The following section details installation and Features of the application

## How to Use 

**Step 1:**

Either download the Repo or clone this repo by using the command below:

```
git clone https://github.com/DuffyCorp/FindMyDog.git
```

**Step 2:**

Go to project root and execute the following command in console to get the required dependencies: 

```
flutter pub get 
```

**Step 3:**

Download the TFlite model from the link above and move it inside the assets folder inside the project

```
flutter-app/
|- assets
```

**Step 4:**

Create a .env file and fill it out with the following data.

```
flutter-app/
|- .env
```

```
FCM_API_KEY=your FCM API key
WHAT3WORDSKEY=your what 3 words API key
TWILIO_SID=your twilio SID
TWILIO_TOKEN=your twilio token
TWILIO_NUM= your twilio number
```

## Find My Dog Features:

* Splash
* Login
* Home
* Routing
* Database
* Provider (State Management)
* Encryption
* Validation
* User Notifications
* Image Classification
* Optical Character Recognition
* Live Chat
* Near by Maps feature
* GeoQueries

### Folder Structure
Here is the core folder structure which flutter provides.

```
flutter-app/
|- android
|- build
|- ios
|- lib
|- test
```

Here is the folder structure we have been using in this project

```
lib/
|- models/
|- providers/
|- resources/
|- responsive/
|- screens/
|- utils/
|- widgets/
|- main.dart
```

Now, lets dive into the lib folder which has the main code for the application.

```
1- models - Models for creating and storing data in Firebase. This allows easy creation of new data objects for firebase as well as coverting them from a firebase snapshot to JSON data to be used within the application.
2- providers - Contains providers for the application for receiveing the users location, if theyre logged in and push notifications.
3- resources -  Contains all methods for interacting with FirebaseAuth, Firestore and FirebaseStorage.
4- responsive - Contains the code for adapting the code to show different content based on mobile or web incase of future expansion to a built in web application.
5- screens — Contains all the screens shown in the application.
6- utils — Contains files for storing variables to be accessed later within the application.
7- widgets — Contains the code for reusable "widgets" the Flutter equivalent to components.
8- main.dart - This is the starting point of the application.
```

## Conclusion

I hope you have success in installing the application and can see its full array of features 🙂

Again to note, this was made for an Honours Project at Glasgow Caledonian University.


