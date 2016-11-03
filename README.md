Manastorm is a javascript replay viewer for Hearthstone, focused on step-by-step play. It is built using coffeescript and reactjs.

#Getting started

* Download and install [NodeJS](https://nodejs.org/en/download/) (we'll need node package manager)
* In a command prompt/bash, run `npm install npm -g` then `npm install`
* Then install grunt-cli using `npm install -g grunt-cli`
* Then install the dependencies with `npm install` and `bower install`
* You can then run manastorm using `grunt serve`. It will by default load the replay from the replay.xml file at the root
    * If you want to load a game from [Zero to Heroes](http://www.zerotoheroes.com), the easiest way is to open the developer tools, monitor the Network activity and look for a request with a guid name, like 5b4711c3-e8be-4a1e-abb8-10aaadddb061. This is the XML of the game being loaded, so just copy-paste the contents into your local file.
