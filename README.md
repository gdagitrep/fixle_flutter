# Fixle Flutter

This is a package to use Fixle in a flutter based app.

Fixle provides a platform for your team of mobile app developers, and product owners,
to exchange feedback seamlessly during the app development phase in real-time.

## Features
1. A user-friendly `Fixle utility bar` appears over your app.

    ![app_bar.png](sample_photos%2Fapp_bar.png)

2. The utility bar provides ability to add comments on app screens (by pressing ![app_bar_plus_sign.png](sample_photos%2Fapp_bar_plus_sign.png)). No need to take screenshots of the app screens and email them.

    ![clip make comment short.gif](sample_photos%2Fclip%20make%20comment%20short.gif)
3. Go through previous comments and participate in conversations with the team, on the app itself, or on the [Fixle Dashboard](https://fixle-dash.web.app/#/)

   ![showing a thread 2.png](sample_photos%2Fshowing%20a%20thread%202.png)
   ![showing a thread.png](sample_photos%2Fshowing%20a%20thread.png)
4. Enable/disable these functionalities for a particular version of this app on [Fixle Dashboard](https://fixle-dash.web.app/#/)-> Settings -> Enabled versions. 

   ![add version_1.gif](sample_photos%2Fadd%20version_1.gif)
   This flexibility means you (developer) can use Fixle during the development process and then turn it off when the app is ready for public release.

[//]: # (When disabled, the users won't see this ability. So, your APPS production versions won't see any Fixle components.&#41;)

### Features Coming soon:
1. Tag team members
2. Login with Google for user identification.

## Installation

For integration, as an app developer, you just need to add 2 lines of code. Following are the steps:
1. Paste ```fixle_flutter_feedback: ^0.0.1``` under `pubspec.yaml` of your flutter APP project.
2. Set up on [Fixle](https://fixle-dash.web.app/#/).
   1. Go to [Fixle Dashboard](https://fixle-dash.web.app/#/) (Sign in if not already)
   2. Go to your project cCreate new project if not already) 
   3. Add the version of your app mentioned in file `pubspec.yaml` 
   4. Copy api key
3. You will need to add fixle to your `pubspec.yaml`
   ```
   dependencies:
    flutter:
      sdk: flutter
    fixle_feedback_flutter: 0.0.1 # use the latest version found on pub.dev
   ```
4. Go to the home widget of your APP project. 
   1. Your home widget is the one which you mention under `MaterialApp(home: HomeWidget())`.
   2. Paste this in the build method of Home Widget:
      ```
      Fixle().showOverlay(context, 'api_key_that_you_copied_above');
      ```

[//]: # (   3. If Home widget is a `StatefulWidget`, also paste `Fixle&#40;&#41;.hideOverlay&#40;&#41;;` in the `dispose&#40;&#41;` method. If you don't have a dispose method, create one using )

[//]: # (      ```)

[//]: # (      @override)

[//]: # (      void dispose&#40;&#41; {)

[//]: # (          Fixle&#40;&#41;.hideOverlay&#40;&#41;;)

[//]: # (          super.dispose&#40;&#41;;)

[//]: # (      })

[//]: # (      ```)
   3. If you have different routes, mentioned under 
      ```
        MaterialApp(home: HomeWidget(), routes: {
            '/search': (context) => SearchPage()
        })
      ``` 
      then you will have to do this for all these route widgets too (`SearchPage` in this example). 
      (Don't worry, there will just be one instance of Fixle utility bar created).
      
4. That's it. When you deploy the app, and change the version, make sure to do step (2.iii) for this new version.

[//]: # (## Usage)


## Additional information
1. Apple only supports digits and `.` for `version` string that you specify in your pubspec.yaml
