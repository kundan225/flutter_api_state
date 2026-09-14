# flutter_api_state

`ApiStateBuilder` — a declarative Flutter widget that replaces repetitive
`FutureBuilder` boilerplate. It handles **loading**, **error**, **empty**, and
**success** states in one place, with built-in **retry**, **pull-to-refresh**,
and an optional **network check**.

## Why

Most screens that talk to an API end up writing the same `FutureBuilder` block:
check `connectionState`, check `hasError`, check for an empty list, then render
the success UI. `ApiStateBuilder` collapses all four branches into one widget —
and adds the things you usually bolt on later (retry, refresh, offline check).

## Install

```yaml
dependencies:
  flutter_api_state: ^1.0.0
```

```dart
import 'package:flutter_api_state/flutter_api_state.dart';
```

## Quick start

Every feature wired up in one widget:

```dart
ApiStateBuilder<List<User>>(
  future: () => fetchUsers(),
  
  loading: const Center(child: CircularProgressIndicator()),
  
  error: (context, error, stack) => Center(child: Text('$error')),
  
  empty: const Center(child: Text('No users')),
  
  success: (context, users) => UserList(users),
  
  enablePullToRefresh: true,
  refreshIndicatorColor: Colors.red,
 
  enableRetry: true,
  retryButtonBuilder: (ctx, onRetry) => OutlinedButton(
    onPressed: onRetry,
    child: const Text('Try again'),
  ),

  enableNetworkCheck: true,
  noNetwork: const Center(child: Text('You are offline. Please reconnect.')),
)
```

Strip out the bits you don't need — only `future` and `success` are required.

> `future` takes a **factory** (`() => fetchUsers()`), not a `Future` directly.
> That's what lets the widget re-invoke it for retry, pull-to-refresh, and
> network re-check.

## Generic support

```dart
ApiStateBuilder<User>(...)
ApiStateBuilder<List<User>>(...)
ApiStateBuilder<Map<String, dynamic>>(...)
ApiStateBuilder<String>(...)
ApiStateBuilder<bool>(...)
```

## Retry button

```dart
ApiStateBuilder<List<User>>(
  future: () => fetchUsers(),
  enableRetry: true,
  retryButtonBuilder: (ctx, onRetry) => OutlinedButton(
    onPressed: onRetry,
    child: const Text('Try again'),
  ),
  error: (ctx, e, _) => Text('$e'),
  success: (ctx, users) => UserList(users),
)
```

Conditions: the button only appears when **all three** are true — the future
threw, `enableRetry: true`, and (optionally) `retryButtonBuilder` is set.
Tapping it re-invokes `future()`.

## Pull-to-refresh

```dart
ApiStateBuilder<List<User>>(
  future: () => fetchUsers(),
  enablePullToRefresh: true,
  refreshIndicatorColor: Colors.red,
  success: (ctx, users) => ListView.builder(/* ... */),
)
```

Works whether your success widget is already a scrollable
(`ListView` / `GridView` / `CustomScrollView`) or a plain widget like `Center`
— the package detects the type and wraps only when needed.

## Network check

Skip the request entirely when the device is offline:

```dart
ApiStateBuilder<List<Post>>(
  future: () => fetchPosts(),
  enableNetworkCheck: true,
  noNetwork: const Center(child: Text('You are offline. Please reconnect.')),
  enableRetry: true,   // shows a Retry button under noNetwork too
  success: (ctx, posts) => PostList(posts),
)
```

The default check resolves DNS for `one.one.one.one` with a 3 s timeout
(mobile/desktop). On web the default is a no-op (`true`) because the browser
already handles its own offline behavior.

**Plug in `connectivity_plus` or your own logic:**

```dart
ApiStateBuilder<List<Post>>(
  future: () => fetchPosts(),
  enableNetworkCheck: true,
  hasNetwork: () async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  },
  noNetwork: const OfflineBanner(),
  success: (ctx, posts) => PostList(posts),
)
```

> Note on captive portals: the default DNS check correctly reports offline on
> hotel/airport Wi-Fi where you're "connected" but blocked. If you want
> "any network present" semantics instead, plug in `connectivity_plus` as
> shown above.

## Full example

The [`example/`](example) folder contains a runnable app that fetches posts
from `jsonplaceholder.typicode.com` with all features turned on:

```dart
ApiStateBuilder<List<dynamic>>(
  future: () => fetchPosts(),
  loading: const Center(child: CircularProgressIndicator()),
  enablePullToRefresh: true,
  refreshIndicatorColor: Colors.red,
  enableRetry: true,
  retryButtonBuilder: (ctx, onRetry) => OutlinedButton(
    onPressed: onRetry,
    child: const Text('Try again'),
  ),
  success: (context, posts) => ListView.builder(
    itemCount: posts.length,
    itemBuilder: (context, i) => Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(posts[i]['title'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(posts[i]['body']),
      ),
    ),
  ),
  error: (context, error, stack) => Center(child: Text('$error')),
  empty: const Center(child: Text('No posts')),
)
```

Run it locally:

```sh
cd example
flutter pub get
flutter run
```

## Cookbook

### 1. API list screen with everything turned on

```dart
ApiStateBuilder<List<Post>>(
  future: () => api.fetchPosts(),
  loading: const Center(child: CircularProgressIndicator()),
  empty: const Center(child: Text('No posts yet')),
  error: (_, e, __) => Center(child: Text('Failed: $e')),
  success: (_, posts) => ListView(
    children: [for (final p in posts) PostTile(p)],
  ),
  enableRetry: true,
  enablePullToRefresh: true,
  enableNetworkCheck: true,
)
```

### 2. User profile API (single object)

```dart
ApiStateBuilder<User>(
  future: () => api.fetchUser(id),
  loading: const CircularProgressIndicator(),
  success: (_, user) => ProfileView(user),
)
```

### 3. Custom empty state

```dart
ApiStateBuilder<List<Task>>(
  future: () => api.fetchTasks(),
  empty: const _NoTasksPlaceholder(),
  success: (_, tasks) => TaskList(tasks),
)
```

### 4. Custom error widget with stack trace

```dart
ApiStateBuilder<Report>(
  future: () => api.fetchReport(),
  error: (_, e, stack) => ErrorView(error: e, stack: stack),
  success: (_, report) => ReportView(report),
)
```

### 5. Skeleton-shimmer loading

```dart
ApiStateBuilder<List<Item>>(
  future: () => api.fetchItems(),
  loading: const ShimmerListSkeleton(),
  success: (_, items) => ItemGrid(items),
)
```

## Contact Developer

kundansatya50@gmail.com


