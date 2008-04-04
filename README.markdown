Ultimate Beast
==============

Beast -  Two's company. Three's a forum. More's a Beast.
--------------------------------------------------------

A fork of small, light-weight forum in Rails with a scary name and a goal of around 500 lines of code when we're done.


How to Obtain Ultimate Beast
----------------------------

1. Grab the latest:

   git clone git://github.com/shirkevich/ultimate-beast.git

2. Customize your database.yml:

   cp config/database.example.yml config/database.yml

3. Load the schema:

   rake db:schema:load

   (You cannot use rake db:migrate to migrate the schema up from 0)

4. Update git submodules:

   git submodule init
   
   git submodule update

5. Launch it:

   script/server


Requiremets
-----------

* gem install RedCloth

* gem install ruby-openid


