## Building

	haxe build.hxml

## Running

Switch to the `neko` or `php` directory.  Run

	nekotools server -rewrite

or

	php -S localhost:2001

as appropriate.  (Install whatever packages your system says are missing, obv.)  Nekotools runs its server at `localhost:2000` by default.

## Testing

	haxe test.hxml

I don't really like the testing setup.  In particular the reliance on `test.hxml` mirroring the build system in `build.hxml`, seems too easy to let them fall out of synch.

## Advanced tips for winners

To reset the board, delete `gothing.sqlite` from `neko/` or `php/` as appropriate.