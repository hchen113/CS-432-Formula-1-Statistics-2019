<!--
  Make sure you have read CONTRIBUTING.md completely before you file a new
  issue! 

  If possible, try to determine if the bug is actually part of the Swift driver,
  or if the issue is actually from `libmongoc` or `libbson`. If so, you should
  file the issue with the representative projects.
-->

## Information

### Swift version

What does this command give you?
```
$ swift --version
```


### Operating system

What does this command give you?
```
$ uname -a
```


### Driver version

What does this command give you?
```
$ cat Package.resolved # Applies if you are using Swift package manager
```


### What is the version(s) of `mongod` that you are running with the driver?
Try running:
```
$ mongod --version
```
or, running this in a MongoDB shell connected to the relevant node(s):
```
> db.version()
```


### What is your server topology?

How is your MongoDB deployment configured?


## What is the problem? 

**BE SPECIFIC**:
* What is the _expected_ behavior and what is _actually_ happening?
* Do you have any particular output that demonstrates this problem?
* Do you have any ideas on _why_ this may be happening that could give us a
clue in the right direction?
* Did this issue arise out of nowhere, or after an update (of the driver,
server, and/or Swift)? 
* Is there a workaround that seems to avoid this this issue?
* Are there multiple ways of triggering this bug (perhaps more than one
function produce a crash)?
* If you know how to reproduce the bug, use the `BugReport` project in our
`Examples/` directory to write some demo code showcasing it so that we have
something to go off of.


## Reproducing the bug

1. First, do this.
2. Then do this.
3. After doing that, do this.
4. And then, finally, do this.
5. Bug occurs.
