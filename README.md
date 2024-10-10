# pocketfunctions-dart

Dart Runtime to run dart functions on Pocketfunctions

---
>Made with ❤️ by Ricardo Markiewicz // [@gazeria](https://twitter.com/gazeria).

## What is this?

This allow developers to create functions than can be deployed and run in a serverless way
on PocketFunctions, a serverless function provider written in Go (link coming soon).

## How to use it

For now, the only way to use this package is to add it as a dependency using `git`. In the
future I may consider publishing this to pub.dev if needed.

```yaml
dependencies:
  pocket_functions:
    git: https://github.com/Gazer/exp-pocketfunct-dart
```

This will allow you to register an entry point for your function by using the `entryPoint`
global variable. We support 3 types of entry points: HTTP, Listeners and Cron.

### HTTP

This will create a http server that answer with the provided function. The function will receive the HTTP
body, query parameters and headers.

You need to check the content type to decode the body properly but we provide some helpers.

For now, your function will receive all HTTP verbs but we will change the API in the future.

```dart
import 'package:pocket_functions/pocket_functions.dart';
import 'package:pocket_functions/entry_point.dart';
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://192.168.0.17:8090');

main() async {
  entryPoint.onRequest((request) async {
    if (request.httpMethod == "GET") {
      final result = await pb.collection("example").getList(
            page: int.tryParse(request.params['page']?[0] ?? "1") ?? 1,
            perPage: 20,
            filter: 'status = true && created >= "2022-08-01"',
            sort: '-created',
          );

      var response =
          request.response.addHeader("content-type", "application/json");

      var items = result.items.map((e) {
        return e.toJson();
      }).toList();
      response.write(items);
      response.close();
    } else if (request.httpMethod == "POST") {
      var name = request.jsonBody()!["name"];
      var status = request.jsonBody()!["status"];

      final body = <String, dynamic>{"name": name, "status": status};

      final record = await pb.collection('example').create(body: body);

      var response =
          request.response.addHeader("content-type", "application/json");
      response.write([record.toJson()]);
      response.close();
    }
  });
}
```

### Listener

This callback is to run code that will check for some condition or react to an external event, like
listening changes in a Pocketbase database; connect to a websocket and react to a message; etc.

This function will run forever and do not have user interaction. It's useful to send emails after registracion,
process invoces; chatbots, etc;

```dart
import 'package:pocket_functions/entry_point.dart' show entryPoint;
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://192.168.0.17:8090');

main() async {
  entryPoint.listen(() {
    pb.collection('example').subscribe(
      '*',
      (e) {
        print(e.action);
        print(e.record);
      },
    );
  });
}
```

### Cron

This entry point schedule a cron job based on the parameter, using a unix cron syntax. When it's,
it execute the callback function and it will run forever without user intervention.

```dart
import 'package:pocket_functions/entry_point.dart';

main() {
  entryPoint.cron("*/1 * * * *", () {
    print("${DateTime.now()} something");
  });
}
```

## Deploy your function

If you have a ProcketFunctions server running you can deploy your function with one command:

```dart
$ my_function> dart run pocket_functions
```

This will zip and upload the code of your function and run the deploy process. If the function is runnin
it will be stopped and restarted with the new code.

## Run functions Locally

Pocketfunctions was designed with the developer in mind, so we want to be sure that testing is easy and
do not require a lot of things.

Right now, to test your function just run your code locally:

```dart
$ my_function> dart rub lib/my_function.dart
```

## Limitations

* Each function will run in a docker container, so you can not share state between them.
* They do not share network or are linked to other containers. If you need to access to a database
you need to use the host IP or any other public.


