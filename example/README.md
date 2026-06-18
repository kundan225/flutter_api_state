# flutter_api_state example

Runnable demo of `ApiStateBuilder` fetching posts from
`https://jsonplaceholder.typicode.com/posts` with:

* Loading spinner while the request is in flight
* Success: scrollable list of post cards
* Error: error message with a custom "Try again" outlined button
* Empty: fallback message when the list is empty
* Pull-to-refresh (red indicator) to re-fetch

## Run

```sh
cd example
flutter pub get
flutter run
```
