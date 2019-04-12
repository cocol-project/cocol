<h1 align="center" style="font-size: 40px; font-weight: 200;">COCOL!</h1>

<div align="center">
  <img src="https://img.shields.io/badge/Stability-Experimental-orange.svg?style=flat square" alt="Stability Experimental" />
  <a href="https://crystal-lang.org">
    <img src="https://img.shields.io/badge/Crystal-0.27.2-blue.svg?style=flat-square" alt="Crystal 0.27.2" />
  </a>
  <img src="https://img.shields.io/badge/License-MPL--2.0-green.svg?style=flat-square" alt="License MPL-2.0" />
</div>

<div align="center">
  <img src="https://img.shields.io/badge/You-didn't_ask_for_this-yellow.svg?style=flat-square" alt="IDDQD IDKFA" />
  <img src="https://img.shields.io/badge/You-got_it_anyway-yellow.svg?style=flat-square" alt="IDDQD IDKFA" />
</div>

------

<p align="center">
  <img src="https://github.com/cocol-project/cocol/blob/master/img/demo.gif" alt="Network" />
</p>


## About
The Cocol Project has the goal to lower the entry barrier for developers interested in building blockchains and dApps.
There is still a long way to go and your help is needed.

## Installation
Cocol is written in [Crystal](https://crystal-lang.org/), so make sure to follow the [installation instructions](https://crystal-lang.org/reference/installation/) first.

After setting up Crystal you can clone the Cocol repository and install the dependencies:
```
> git clone https://gitlab.com/cocol/cocol.git
> cd cocol
> shards install
```

## Usage
Make your changes to the code-base and than build Cocol
```
> shards build
```
The binary `./bin/cocol` offers the following CLI options

```
Options:

-p --port            The port your Cocol node is going to run on
-m --master          Making this node a master (there can only be one)
--max-connections    Setting the max-connections for peers.
--miner              Making this node a miner
--update             Triggering an update on launch (will catch up with the current height)

```

There is also a script that starts multiple nodes and the master for you

```
> ./script/start.sh 66 5
```
First number is the amount of nodes and the second max-connections per node.
It will start the master node with the port `3000` and every other node with `3000 + n`


You can now start one or several miner like this:
```
> ./cocol -p 4100 --max-connections 5 --miner
```

Now go ahead and open the explorer in a browser:
```
> open ./explorer/index.html
```

You should see 66 nodes and a miner (red border)

Each one of the nodes has a REST API on the corresponding port (e.g. `3001`)

You can create transactions or query the current ledger

## Development

Cocol is in a very early stage. Expect changes, bugs and messy code.

## Contributing

1. Fork it ( https://github.com/cocol-project/cocol/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [github: [cserb]](https://github.com/cserb) [twitter: [@cerbivore]](http://twitter.com/cerbivore) Cristian Serb - creator, maintainer
