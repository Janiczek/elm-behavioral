This could be published but I'm not yet convinced it's useful :sweat_smile:

Drop me a message if you think it would be useful for you!

## Run the examples:

```bash
$ make goodMorning # canonical example
$ make diningPhilosophers
$ make ticTacToe # running in conjunction with normal Platform.worker-like app!
```

## Reading:


### Harel
- http://www.wisdom.weizmann.ac.il/~bprogram/ - homepage
- http://www.wisdom.weizmann.ac.il/~bprogram/pres/BPintroduction.pdf - introduction slides, pretty good and comprehensive!
- http://www.wisdom.weizmann.ac.il/~amarron/BP%20-%20CACM%20-%20Author%20version.pdf - original paper
- http://www.wisdom.weizmann.ac.il/~harel/papers/ - a trove of information :upside_down_face:

### L. Matteis
- https://medium.com/@lmatteis/b-threads-programming-in-a-way-that-allows-for-easier-changes-5d95b9fb6928  - introduction post
- https://lmatteis.github.io/react-behavioral/ - interactive demo
- https://github.com/lmatteis/behavioral/ - JS library
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

## Caveats:

The contents of `BThread`s can't run arbitrary code (consequence of using Elm) nor dynamically add more `BThread`s (we could theoretically add this).
Thus I wasn't able to translate the PrimeFactors example from the original paper.
