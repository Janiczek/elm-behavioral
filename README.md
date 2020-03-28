This could be published but I'm not yet convinced it's useful :sweat_smile:

Drop me a message if you think it would be useful for you!

## Run the examples:

```bash
$ make goodMorning # canonical example
$ make diningPhilosophers
$ make ticTacToe # running in conjunction with normal Platform.worker-like app!
```

## Reading:

- http://www.wisdom.weizmann.ac.il/~bprogram/
- http://www.wisdom.weizmann.ac.il/~bprogram/pres/BPintroduction.pdf
- https://medium.com/@lmatteis/b-threads-programming-in-a-way-that-allows-for-easier-changes-5d95b9fb6928 
- https://lmatteis.github.io/react-behavioral/
- https://github.com/lmatteis/behavioral/
- https://github.com/lmatteis/react-behavioral/
- https://github.com/lmatteis/redux-behavioral/

## TODO:

- [ ] `BProgram.element`
- [ ] `BProgram.document`
- [ ] `BProgram.application`
- [ ] priorities
- [ ] dynamic addition of BThreads?
- [ ] example - quadrotor. Would need `BProgram.element/document/application` - something `Html`-based, to visualize nicely; also to introduce randomness through events requested from user program. See ["Introduction to BP" [PDF]](http://www.wisdom.weizmann.ac.il/~bprogram/pres/BPintroduction.pdf), pages 27-29
- [ ] have an option for random selection of events instead of `List.head`
