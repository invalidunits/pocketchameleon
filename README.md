# pocketchameleon

A mobile adaption of the viral game, Meccha Chamelion.


## Setup and Launch

First install all of the dependenices.
```sh
flutter pub get
```

You can launch the app with
```sh
flutter run
```

However, with these instructions alone you will not be able to act this. You must setup Amazon AWS cognito to login.


### Setup AWS Cognito Login

The app uses AWS Amplify Auth with an Amazon Cognito User Pool. Configure the
pool to allow **email** as a sign-in option and create a public app client
without a client secret. The app expects existing accounts; user registration
is not included.

Provide the User Pool's region, ID, and app client ID at launch or through and environment file:


### At Launch
```sh
flutter run \
  --dart-define=COGNITO_REGION=us-east-1 \
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_example \
  --dart-define=COGNITO_APP_CLIENT_ID=exampleclientid
```

### Environment File
Create the file assets/.env with 
```sh 
COGNITO_REGION=us-east-1
COGNITO_USER_POOL_ID=us-east-1_example
COGNITO_APP_CLIENT_ID=exampleclientid
```
If you are grading this, I've provided a sample AWS environemnt file with the submittion in Canvas.

## AI Acknowledgements

I acknowledge the use of Copilot (https://copilot.microsoft.com/chats/4sXYbqomdFiKJ1cH6dR7b) to help reformat and style UI and UX. 
