# Fixle Flutter

This is a package to use Fixle on UI of a flutter app.

Fixle provides a platform for mobile app developers, product managers, and designers,
to collaborate seamlessly and get feedback on your app development process in real-time.

## Features
1. No need to take screenshots of the app screens and email them to your team. Fixle does that for you; you just need to add comments on those screens, and fixle does the rest.
2. Go through previous comments and participate in conversations with the team.
3. Enable/disable these functionalities for a particular version of this app, with the switch of a button on [Fixle Dashboard](https://fixle-dash.web.app/#/)-> Settings -> Enabled versions. 

Some screenshots showing these features:

![app_bar.png](sample_photos%2Fapp_bar.png)
![showing a thread 2.png](sample_photos%2Fshowing%20a%20thread%202.png)
![showing a thread.png](sample_photos%2Fshowing%20a%20thread.png)

[//]: # (When disabled, the users won't see this ability. So, your APPS production versions won't see any Fixle components.&#41;)

### Features Coming soon:
1. Tag team members
2. Login with Google for user identification.

## Installation

For integration, as an app developer you just need to add 2 lines of code. Following are the steps:
1. Set up on [Fixle](https://fixle-dash.web.app/#/).
   1. Go to [Fixle Dashboard](https://fixle-dash.web.app/#/) (Sign in if not already)
   2. Create new project 
   3. Add the version of your app mentioned in file `pubspec.yaml` 
   4. Copy api key
2. Go to the home widget of your app. 
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
      
4. That's it. When you deploy the app, and change the version, make sure to do step 1.iii for this new version.

[//]: # (## Usage)


## Additional information
1. Apple only supports digits and `.` for `version` string that you specify in your pubspec.yaml
