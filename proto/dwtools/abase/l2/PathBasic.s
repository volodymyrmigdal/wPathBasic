( function _PathBasic_s_() {

'use strict';

/**
 * Collection of routines to operate paths reliably and consistently. Path leverages parsing,joining,extracting,normalizing,nativizing,resolving paths. Use the module to get uniform experience from playing with paths on different platforms.
  @module Tools/base/Path
*/

/**
 * @summary Collection of routines to operate paths reliably and consistently.
 * @namespace wTools.path
 * @extends Tools
 * @module Tools/PathBasic
 */

if( typeof module !== 'undefined' )
{

  let _ = require( '../../../dwtools/Tools.s' );

}

//

let _global = _global_;
let _ = _global_.wTools;
_.assert( !!_.path );
let Self = _.path = _.path || Object.create( null );

// --
// checker
// --

/* xxx qqq : make new version in module Files. ask */
function like( path )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  if( this.is( path ) )
  return true;
  if( _.FileRecord )
  if( path instanceof _.FileRecord )
  return true;
  return false;
}

//

function isElement( pathElement )
{
  return pathElement === null || _.strIs( pathElement ) || _.arrayIs( pathElement ) || _.mapIs( pathElement ) || _.boolLike( pathElement ) || _.regexpIs( pathElement );
}

//

/**
 * Checks if string is correct possible for current OS path and represent file/directory that is safe for modification
 * (not hidden for example).
 * @param {String} filePath Source path for check
 * @returns {boolean}
 * @function isSafe
 * @namespace Tools.path
 */

function isSafe( filePath,level )
{
  filePath = this.normalize( filePath );

  if( level === undefined )
  level = 1;

  _.assert( arguments.length === 1 || arguments.length === 2 );
  _.assert( _.numberIs( level ), 'Expects number {- level -}' );

  if( level >= 1 )
  {
    if( this.isAbsolute( filePath ) )
    {
      let parts = filePath.split( this.upToken ).filter( ( p ) => p.trim() );
      if( process.platform === 'win32' && parts.length && parts[ 0 ].length === 1 )
      parts.splice( 0, 1 );
      if( parts.length <= 1 )
      return false;
      if( level >= 2 && parts.length <= 2 )
      return false;
      return true;
    }
  }

  if( level >= 2 && process.platform === 'win32' )
  {
    if( _.strHas( filePath, 'Windows' ) )
    return false;
    if( _.strHas( filePath, 'Program Files' ) )
    return false;
  }

  if( level >= 2 )
  if( /(^|\/)\.(?!$|\/|\.)/.test( filePath ) )
  return false;

  if( level >= 3 )
  if( /(^|\/)node_modules($|\/)/.test( filePath ) )
  return false;

  return true;
}

//

function isGlob( src )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( src ) );

  if( self.fileProvider && !self.fileProvider.globing )
  {
    return false;
  }

  if( !self._pathIsGlobRegexp )
  _setup();

  return self._pathIsGlobRegexp.test( src );

  function _setup()
  {
    let _pathIsGlobRegexpStr = '';
    _pathIsGlobRegexpStr += '(?:[?*]+)'; /* asterix,question mark */
    _pathIsGlobRegexpStr += '|(?:([!?*@+]*)\\((.*?(?:\\|(.*?))*)\\))'; /* parentheses */
    _pathIsGlobRegexpStr += '|(?:\\[(.+?)\\])'; /* square brackets */
    _pathIsGlobRegexpStr += '|(?:\\{(.*)\\})'; /* curly brackets */
    _pathIsGlobRegexpStr += '|(?:\0)'; /* zero */
    self._pathIsGlobRegexp = new RegExp( _pathIsGlobRegexpStr );
  }

}

//

function hasSymbolBase( srcPath )
{
  return _.strHasAny( srcPath, [ '\0', '()' ] );
}

// --
// transformer
// --

/**
 * Returns dirname + filename without extension
 * @example
 * _.path.prefixGet( '/foo/bar/baz.ext' ); // '/foo/bar/baz'
 * @param {string} path Path string
 * @returns {string}
 * @throws {Error} If passed argument is not string.
 * @function prefixGet
 * @namespace Tools.path
 */

function prefixGet( path )
{

  _.assert( _.strIs( path ), 'Expects string as path' );

  let n = path.lastIndexOf( '/' );
  if( n === -1 ) n = 0;

  let parts = [ path.substr( 0, n ),path.substr( n ) ];

  n = parts[ 1 ].indexOf( '.' );
  if( n === -1 )
  n = parts[ 1 ].length;

  let result = parts[ 0 ] + parts[ 1 ].substr( 0,n );

  return result;
}

//

/**
 * Returns path name (file name).
 * @example
 * wTools.name( '/foo/bar/baz.asdf' ); // 'baz'
 * @param {string|object} path|o Path string,or options
 * @param {boolean} o.full if this parameter set to true method return name with extension.
 * @returns {string}
 * @throws {Error} If passed argument is not string
 * @function name
 * @namespace Tools.path
 */

function name_pre( routine, args )
{
  let o = args[ 0 ];
  if( _.strIs( o ) )
  o = { path : o };

  _.routineOptions( routine, o );
  _.assert( args.length === 1 );
  _.assert( arguments.length === 2 );
  _.assert( _.strIs( o.path ), 'Expects string {-o.path-}' );

  return o;
}

function name_body( o )
{

  if( _.strIs( o ) )
  o = { path : o };

  _.assertRoutineOptions( name, arguments );

  o.path = this.canonize( o.path );

  let i = o.path.lastIndexOf( '/' );
  if( i !== -1 )
  o.path = o.path.substr( i+1 );

  if( !o.full )
  {
    let i = o.path.lastIndexOf( '.' );
    if( i !== -1 ) o.path = o.path.substr( 0, i );
  }

  return o.path;
}

name_body.defaults =
{
  path : null,
  full : 0,
}

let name = _.routineFromPreAndBody( name_pre, name_body );
name.defaults.full = 0;

let fullName = _.routineFromPreAndBody( name_pre, name_body );
fullName.defaults.full = 1;

//

/**
 * Return path without extension.
 * @example
 * wTools.withoutExt( '/foo/bar/baz.txt' ); // '/foo/bar/baz'
 * @param {string} path String path
 * @returns {string}
 * @throws {Error} If passed argument is not string
 * @function withoutExt
 * @namespace Tools.path
 */

function withoutExt( path )
{

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ), 'Expects string' );

  let name = _.strIsolateRightOrNone( path,'/' )[ 2 ] || path;

  let i = name.lastIndexOf( '.' );
  if( i === -1 || i === 0 )
  return path;

  let halfs = _.strIsolateRightOrNone( path,'.' );
  return halfs[ 0 ];
}

//

/**
 * Returns file extension of passed `path` string.
 * If there is no '.' in the last portion of the path returns an empty string.
 * @example
 * _.path.ext( '/foo/bar/baz.ext' ); // 'ext'
 * @param {string} path path string
 * @returns {string} file extension
 * @throws {Error} If passed argument is not string.
 * @function ext
 * @namespace Tools.path
 */

function ext( path )
{

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ), 'Expects string {-path-}, but got', _.strType( path ) );

  let index = path.lastIndexOf( '/' );
  if( index >= 0 )
  path = path.substr( index+1, path.length-index-1  );

  index = path.lastIndexOf( '.' );
  if( index === -1 || index === 0 )
  return '';

  index += 1;

  return path.substr( index, path.length-index ).toLowerCase();
}

//

/*
qqq : not covered by tests | Dmytro : covered
*/

function exts( path )
{

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ), 'Expects string {-path-}, but got', _.strType( path ) );

  path = this.name({ path,full : 1 });

  let exts = path.split( '.' );
  exts.splice( 0, 1 );
  exts = _.entityFilter( exts , ( e ) => !e ? undefined : e.toLowerCase() );

  return exts;
}

//

/**
 * Replaces existing path extension on passed in `ext` parameter. If path has no extension,adds passed extension
    to path.
 * @example
 * wTools.changeExt( '/foo/bar/baz.txt', 'text' ); // '/foo/bar/baz.text'
 * @param {string} path Path string
 * @param {string} ext
 * @returns {string}
 * @throws {Error} If passed argument is not string
 * @function changeExt
 * @namespace Tools.path
 */

// qqq : extend tests | Dmytro : coverage is extended

function changeExt( path, ext )
{

  if( arguments.length === 2 )
  {
    _.assert( _.strIs( ext ) );
  }
  else if( arguments.length === 3 )
  {
    let sub = arguments[ 1 ];
    // let ext = arguments[ 2 ]; // Dmytro : it's local variable, uses in assertion below and has no sense in routine
    ext = arguments[ 2 ];

    _.assert( _.strIs( sub ) );
    _.assert( _.strIs( ext ) );

    let cext = this.ext( path );

    if( cext !== sub )
    return path;
  }
  else
  {
    _.assert( 0, 'Expects 2 or 3 arguments' );
  }

  if( ext === '' )
  return this.withoutExt( path );
  else
  return this.withoutExt( path ) + '.' + ext;

}

//

function _pathsChangeExt( src )
{
  _.assert( _.longIs( src ) );
  _.assert( src.length === 2 );

  return changeExt.apply( this,src );
}

// --
// joiner
// --

/**
 * Joins filesystem paths fragments or urls fragment into one path/url. Uses '/' level delimeter.
 * @param {Object} o join o.
 * @param {String[]} p.paths - Array with paths to join.
 * @param {boolean} [o.reroot=false] If this parameter set to false (by default), method joins all elements in
 * `paths` array,starting from element that begins from '/' character,or '* :', where '*' is any drive name. If it
 * is set to true,method will join all elements in array. Result
 * @returns {string}
 * @private
 * @throws {Error} If missed arguments.
 * @throws {Error} If elements of `paths` are not strings
 * @throws {Error} If o has extra parameters.
 * @function join_body
 * @namespace Tools.path
 */

/* xxx : implement routine _.path.joiner() */

function join_pre( routine, args )
{
  _.assert( args.length > 0, 'Expects argument' )
  let o = { paths : args };

  _.routineOptions( routine, o );
  //_.assert( o.paths.length > 0 );
  _.assert( _.boolLike( o.reroot ) );
  _.assert( _.boolLike( o.allowingNull ) );
  _.assert( _.boolLike( o.raw ) );

  return o;
}

function join_body( o )
{
  let self = this;
  let result = null;
  let prepending = true;

  /* */

  if( Config.debug )
  for( let a = o.paths.length-1 ; a >= 0 ; a-- )
  {
    let src = o.paths[ a ];
    _.assert( _.strIs( src ) || src === null, () => `Expects strings as path arguments, but #${a} argument is ${_.strType( src )}` );
  }

  /* */

  for( let a = o.paths.length-1 ; a >= 0 ; a-- )
  {
    let src = o.paths[ a ];

    if( o.allowingNull )
    if( src === null )
    break;

    if( result === null )
    result = '';

    _.assert( _.strIs( src ), () => `Expects strings as path arguments, but #${a} argument is ${_.strType( src )}` );

    if( !prepend( src ) )
    break;

  }

  /* */

  if( !o.raw && result !== null )
  result = self.normalize( result );

  return result;

  /* */

  function prepend( src )
  {
    let trailed = false;
    let endsWithUp = false;

    if( src )
    src = self.refine( src );

    if( !src )
    return true;

    // src = src.replace( /\\/g, self.upToken );

    // if( result )
    if( _.strEnds( src, self.upToken ) )
    // if( _.strEnds( src, self.upToken ) && !_.strEnds( src, self.upToken + self.upToken ) )
    // if( src.length > 1 || result[ 0 ] === self.upToken )
    {
      if( src.length > 1 )
      {
        if( result )
        src = src.substr( 0, src.length-1 );
        trailed = true;

        if( result === self.downToken )
        result = self.hereToken;
        else if( result === self.downUpToken )
        result = self.hereUpToken;
        else
        result = _.strRemoveBegin( result, self.downUpToken );

      }
      else
      {
        endsWithUp = true;
      }
    }

    if( src && result )
    if( !endsWithUp && !_.strBegins( result, self.upToken ) )
    result = self.upToken + result;

    result = src + result;

    if( !o.reroot )
    {
      if( _.strBegins( result, self.rootToken ) )
      return false;
    }

    return true;
  }

}

join_body.defaults =
{
  paths : null,
  reroot : 0,
  allowingNull : 1,
  raw : 0,
}

//

/**
 * Method joins all `paths` together,beginning from string that starts with '/', and normalize the resulting path.
 * @example
 * let res = wTools.join( '/foo', 'bar', 'baz', '.');
 * // '/foo/bar/baz'
 * @param {...string} paths path strings
 * @returns {string} Result path is the concatenation of all `paths` with '/' directory delimeter.
 * @throws {Error} If one of passed arguments is not string
 * @function join
 * @namespace Tools.path
 */

let join = _.routineFromPreAndBody( join_pre, join_body );

//

let joinRaw = _.routineFromPreAndBody( join_pre, join_body );
joinRaw.defaults.raw = 1;

// function join()
// {
//
//   let result = this.join_body
//   ({
//     paths : arguments,
//     reroot : 0,
//     allowingNull : 1,
//     raw : 0,
//   });
//
//   return result;
// }

//

// function joinRaw_body( o )
// {
//   let result = this.join.body( o );
//
//   return result;
// }
//
// joinRaw_body.defaults =
// {
//   paths : null,
//   reroot : 0,
//   allowingNull : 1,
//   raw : 1,
// }

// function joinRaw()
// {
//
//   let result = this.join_body
//   ({
//     paths : arguments,
//     reroot : 0,
//     allowingNull : 1,
//     raw : 1,
//   });
//
//   return result;
// }

//

function joinIfDefined()
{
  let args = _.filter( arguments, ( arg ) => arg );
  if( !args.length )
  return;
  return this.join.apply( this,args );
}

//

function joinCross()
{

  if( _.longHasDepth( arguments ) )
  {
    let result = [];

    let samples = _.eachSample( arguments );
    for( var s = 0 ; s < samples.length ; s++ )
    result.push( this.join.apply( this,samples[ s ] ) );
    return result;

  }

  return this.join.apply( this,arguments );
}

//

/**
 * Method joins all `paths` strings together.
 * @example
 * let res = wTools.reroot( '/foo', '/bar/', 'baz', '.');
 * // '/foo/bar/baz/.'
 * @param {...string} paths path strings
 * @returns {string} Result path is the concatenation of all `paths` with '/' directory delimeter.
 * @throws {Error} If one of passed arguments is not string
 * @function reroot
 * @namespace Tools.path
 */

let reroot = _.routineFromPreAndBody( join_pre, join_body );
reroot.defaults =
{
  paths : arguments,
  reroot : 1,
  allowingNull : 1,
  raw : 0,
}

// function reroot()
// {
//   let result = this.join_body
//   ({
//     paths : arguments,
//     reroot : 1,
//     allowingNull : 1,
//     raw : 0,
//   });
//   return result;
// }

//

/**
 * Method resolves a sequence of paths or path segments into an absolute path.
 * The given sequence of paths is processed from right to left,with each subsequent path prepended until an absolute
 * path is constructed. If after processing all given path segments an absolute path has not yet been generated,
 * the current working directory is used.
 * @example
 * let absPath = wTools.resolve('work/wFiles'); // '/home/user/work/wFiles';
 * @param [...string] paths A sequence of paths or path segments
 * @returns {string}
 * @function resolve
 * @namespace Tools.path
 */

function resolve()
{
  let args = []
  let hasNull;

  for( let i = arguments.length - 1 ; i >= 0 ; i-- )
  {
    let arg = arguments[ i ];

    if( _.strIs( arg ) && _.strHas( arg, '://' ) )
    debugger;

    if( arg !== null )
    {
      args.unshift( arg );
    }
    else
    {
      hasNull = true;
      break;
    }
  }

  if( args.length === 0 )
  {
    if( hasNull )
    return null;
    return this.current();
  }

  let result = this.join.apply( this, args );
  if( hasNull || this.isAbsolute( result ) )
  return result;

  return this.join( this.current(), result );
}

// {
//   let path;
//
//   _.assert( arguments.length >= 0 );
//
//   let result = this.join( this.current(), ... arguments );
//
//   if( result !== null )
//   _.assert( result.length > 0 );
//
//   return result;
// }

// function resolve()
// {
//   let path;
//
//   _.assert( arguments.length > 0 );
//
//   path = this.join.apply( this, arguments );
//
//   if( path === null )
//   return path;
//   else if( !this.isAbsolute( path ) )
//   path = this.join( this.current(), path );
//
//   path = this.normalize( path );
//
//   _.assert( path.length > 0 );
//
//   return path;
// }

//

function joinNames()
{

  // Variables

  let prefixs = [];         // Prefixes array
  let names = [];           // Names array
  let exts = [];            // Extensions array
  let extsBool = false;     // Check if there are extensions
  let prefixBool = false;   // Check if there are prefixes
  let start = -1;           // Index of the starting prefix
  let numStarts = 0;        // Number of starting prefixes
  let numNull = 0;          // Number of null prefixes
  let longerI = -1;         // Index of the longest prefix
  let maxPrefNum = 0;       // Length of the longest prefix

  // Check input elements are strings
  if( Config.debug )
  for( let a = arguments.length-1 ; a >= 0 ; a-- )
  {
    let src = arguments[ a ];
    _.assert( _.strIs( src ) || src === null );
  }

  for( let a = arguments.length-1 ; a >= 0 ; a-- ) // Loop over the arguments ( starting by the end )
  {
    let src = arguments[ a ];

    if( src === null )  // Null arg,break loop
    {
      prefixs.splice( 0,a + 1 );
      numNull = numNull + a + 1;
      break;
    }

    src = this.normalize(  src );

    let prefix = this.prefixGet( src );

    if( prefix.charAt( 0 ) === '/' )   // Starting prefix
    {
      prefixs[ a ] = src + '/';
      names[ a ] = '';
      exts[ a ] = '';
      start = a;
      numStarts = numStarts + 1;
    }
    else
    {
      names[ a ] = this.name( src );
      prefixs[ a ] = prefix.substring( 0,prefix.length - ( names[ a ].length + 1 ) );
      prefix = prefix.substring( 0,prefix.length - ( names[ a ].length ) );
      exts[ a ] = this.ext( src );

      if( prefix.substring( 0,2 ) === './')
      {
        prefixs[ a ] = prefixs[ a ].substring( 2 );
      }

      prefixs[ a ] = prefixs[ a ].split("/");

      let prefNum = prefixs[ a ].length;

      if( maxPrefNum < prefNum )
      {
        maxPrefNum = prefNum;
        longerI = a;
      }

      let empty = prefixs[ a ][ 0 ] === '' && names[ a ] === '' && exts[ a ] === '';

      if( empty && src.charAt( 0 ) === '.' )
      exts[ a ] = src.substring( 1 );

    }

    if( exts[ a ] !== '' )
    extsBool = true;

    if( prefix !== '' )
    prefixBool = true;

  }

  longerI = longerI - numStarts - numNull;

  let result = names.join( '' );

  if( prefixBool === true )
  {
    if( start !== -1 )
    {
      logger.log( prefixs,start)
      var first = prefixs.splice( start,1 );
    }

    for( let p = 0; p < maxPrefNum; p++ )
    {
      for( let j = prefixs.length - 1; j >= 0; j-- )
      {
        let pLong = prefixs[ longerI ][ maxPrefNum - 1 - p ];
        let pj = prefixs[ j ][ prefixs[ j ].length - 1 - p ];
        if( j !== longerI )
        {
          if( pj !== undefined && pLong !== undefined )
          {

            if( j < longerI )
            {
              prefixs[ longerI ][ maxPrefNum - 1 - p ] =  this.joinNames.apply( this, [ pj,pLong ] );
            }
            else
            {
              prefixs[ longerI ][ maxPrefNum - 1 - p ] =  this.joinNames.apply( this, [ pLong,pj ] );
            }
          }
          else if( pLong === undefined  )
          {
            prefixs[ longerI ][ maxPref - 1 - p ] =  pj;
          }
          else if( pj === undefined  )
          {
            prefixs[ longerI ][ maxPrefNum - 1 - p ] =  pLong;
          }
        }
      }
    }

    let pre = this.join.apply( this,prefixs[ longerI ] );
    result = this.join.apply( this, [ pre,result ] );

    if( start !== -1 )
    {
      result =  this.join.apply( this, [ first[ 0 ], result ] )
    }

  }

  if( extsBool === true )
  {
    result = result + '.' + exts.join( '' );
  }

  // qqq : what is normalize for?
  result = this.normalize( result );

  return result;
}

/*
function joinNames()
{
  let names = [];
  let exts = [];

  if( Config.debug )
  for( let a = arguments.length-1 ; a >= 0 ; a-- )
  {
    let src = arguments[ a ];
    _.assert( _.strIs( src ) || src === null );
  }

  for( let a = arguments.length-1 ; a >= 0 ; a-- )
  {
    let src = arguments[ a ];
    if( src === null )
    break;
    names[ a ] = this.name( src );
    exts[ a ] = src.substring( names[ a ].length );
  }

  let result = names.join( '' ) + exts.join( '' );

  return result;
}
*/

// --
// stater
// --

function current()
{
  _.assert( arguments.length === 0, 'Expects no arguments' );
  // return this.hereToken;
  return this.upToken;
}

//

function from( src )
{

  _.assert( arguments.length === 1, 'Expects single argument' );

  if( _.strIs( src ) )
  return src;
  else
  _.assert( 0, 'Expects string, but got ' + _.strType( src ) );

}

// --
// relator
// --

/**
* Returns a relative path to `path` from an `relative` path. This is a path computation : the filesystem is not
* accessed to confirm the existence or nature of path or start.

* * If `o.relative` and `o.path` each resolve to the same path method returns `.`.
* * If `o.resolving` is enabled -- paths `o.relative` and `o.path` are resolved before computation, uses result of {@link module:Tools/PathBasic.Path.current _.path.current} as base.
* * If `o.resolving` is disabled -- paths `o.relative` and `o.path` are not resolved and must be both relative or absolute.
*
* **Examples of how result is computed and how to chech the result:**
*
* Result is checked by a formula : from + result === to, where '+' means join operation {@link module:Tools/PathBasic.Path.join _.path.join}
*
* **Note** :
* * `from` -- `o.relative`
* * `to` -- `o.path`
* * `cd` -- current directory
*
* *Example #1*
*   ```
*   from : /a
*   to : /b
*   result : ../b
*   from + result = to : /a + ../b = /b
*   ```
* *Example #2*
*   ```
*   from : /
*   to : /b
*   result : ./b
*   from + result = to : / + ./b = /b
*   ```
* *Example #3*
*   ```
*   resolving : 0
*   from : ..
*   to : .
*   result : .
*   from + result = to : .. + . != .. <> . -- error because result doesn't satisfy the final check
*   from + result = to : .. + .. != ../.. <> . -- error because result doesn't satisfy the final check
*   ```
*
* *Example #4*
*   ```
*   resolving : 1
*   cd : /d -- current dir
*   from : .. -> /
*   to : . -> /d
*   result : ./d
*   from + result = to : / + ./d === /d
*   ```
*
* *Example #5*
*   ```
*   resolving : 0
*   from : ../a/b
*   to : ../c/d
*   result : ../../c/d
*   from + result = to : ../a/b + ../../c/d === ../c/d
*   ```
*
* *Example #6*
*   ```
*   resolving : 1
*   cd : /
*   from : ../a/b -> /../a/b
*   to : ../c/d -> /../c/d
*   from + result = to : /../a/b + /../../c/d === /../c/d -- error resolved "from" leads out of file system
*   ```
*
* *Example #7*
*   ```
*   resolving : 0
*   from : ..
*   to : ./a
*   result : ../a
*   from + result = to : .. + ../a != ./a -- error because result doesn't satisfy the final check
*   ```
* *Example #8*
*   ```
*   resolving : 1
*   cd : /
*   from : .. -> /..
*   to : ./a -> /a
*   result : /../a
*   from + result = to : .. + ../a != ./a -- error resolved "from" leads out of file system
*   ```
*
* @param {Object} [o] Options map.
* @param {String|wFileRecord} [o.relative] Start path.
* @param {String|String[]} [o.path] Targer path(s).
* @param {String|String[]} [o.resolving=0] Resolves {o.relative} and {o.path} before computation.
* @param {String|String[]} [o.dotted=1] Allows '.' as the result, otherwise returns empty string.
* @returns {String|String[]} Returns relative path as String or array of Strings.
* @throws {Exception} If {o.resolving} is enabled and {o.relative} or {o.path} leads out of file system.
* @throws {Exception} If result of computation doesn't satisfy formula: o.relative + result === o.path.
* @throws {Exception} If {o.relative} is not a string or wFileRecord instance.
* @throws {Exception} If {o.path} is not a string or array of strings.
* @throws {Exception} If both {o.relative} and {path} are not relative or absolute.
*
* @example
* let from = '/a';
* let to = '/b'
* _.path._relative({ relative : from, path : to, resolving : 0 });
* //'../b'
*
* @example
* let from = '../a/b';
* let to = '../c/d'
* _.path._relative({ relative : from, path : to, resolving : 0 });
* //'../../c/d'
*
* @example
* //resolving, assume that cd is : '/d'
* let from = '..';
* let to = '.'
* _.path._relative({ relative : from, path : to, resolving : 1 });
* //'./d'
*
* @function _relative
* @namespace Tools.path
*/

function _relative( o )
{
  let self = this;
  let result = '';
  // let basePath = this.from( o.basePath );
  // let filePath = this.from( o.filePath );

  o.basePath = this.from( o.basePath );
  o.filePath = this.from( o.filePath );

  _.assert( _.strIs( o.basePath ),'Expects string {-o.basePath-}, but got', _.strType( o.basePath ) );
  _.assert( _.strIs( o.filePath ) || _.arrayIs( o.filePath ) );
  _.assertRoutineOptions( _relative, arguments );

  if( o.resolving )
  {
    o.basePath = this.resolve( o.basePath );
    o.filePath = this.resolve( o.filePath );
  }
  else
  {
    o.basePath = this.normalize( o.basePath );
    o.filePath = this.normalize( o.filePath );
  }

  let basePath = o.basePath;
  let filePath = o.filePath;
  let baseIsAbsolute = self.isAbsolute( basePath );
  let fileIsAbsolute = self.isAbsolute( filePath );
  let baseIsTrailed = self.isTrailed( basePath );

  /* makes common style for relative paths, each should begin from './' */

  if( o.resolving )
  {

    basePath = this.resolve( basePath );
    filePath = this.resolve( filePath );

    _.assert( this.isAbsolute( basePath ) );
    _.assert( this.isAbsolute( filePath ) );

    _.assert
    (
        !_.strBegins( basePath, this.upToken + this.downToken )
      , 'Resolved o.basePath:', basePath, 'leads out of file system.'
    );
    _.assert
    (
        !_.strBegins( filePath, this.upToken + this.downToken )
      , 'Resolved o.filePath:', filePath, 'leads out of file system.'
    );

  }
  else
  {
    basePath = this.normalize( basePath );
    filePath = this.normalize( filePath );

    let baseIsAbsolute = this.isAbsolute( basePath );
    let fileIsAbsolute = this.isAbsolute( filePath );

    /* makes common style for relative paths, each should begin with './' */

    // if( !baseIsAbsolute && basePath !== this.hereToken )
    // basePath = _.strPrependOnce( basePath, this.hereUpToken );
    // if( !fileIsAbsolute && filePath !== this.hereToken )
    // filePath = _.strPrependOnce( filePath, this.hereUpToken );

    if( !baseIsAbsolute )
    basePath = _.strRemoveBegin( basePath, this.hereUpToken );
    if( !fileIsAbsolute )
    filePath = _.strRemoveBegin( filePath, this.hereUpToken );

    while( beginsWithDown( basePath ) )
    {
      if( !beginsWithDown( filePath ) )
      break;
      basePath = removeBeginDown( basePath );
      filePath = removeBeginDown( filePath );
    }

    _.assert
    (
        ( baseIsAbsolute && fileIsAbsolute ) || ( !baseIsAbsolute && !fileIsAbsolute )
      , 'Both paths must be either absolute or relative.'
    );

    _.assert
    (
        // basePath !== this.hereUpToken + this.downToken && !_.strBegins( basePath, this.hereUpToken + this.downUpToken )
        !beginsWithDown( basePath )
      , `Cant get path relative base path "${o.basePath}", it begins with "${this.downToken}"`
    );

    if( !baseIsAbsolute && basePath !== this.hereToken )
    basePath = _.strPrependOnce( basePath, this.hereUpToken );
    if( !fileIsAbsolute && filePath !== this.hereToken )
    filePath = _.strPrependOnce( filePath, this.hereUpToken );

  }

  _.assert( basePath.length > 0 );
  _.assert( filePath.length > 0 );

  /* extracts common filePath and checks if its a intermediate dir, otherwise cuts filePath and repeats the check*/

  let common = _.strCommonLeft( basePath, filePath );
  let commonTrailed = _.strAppendOnce( common, this.upToken );
  if
  (
        !_.strBegins( _.strAppendOnce( basePath, this.upToken ), commonTrailed )
    ||  !_.strBegins( _.strAppendOnce( filePath, this.upToken ), commonTrailed )
  )
  {
    common = this.dir( common );
  }

  /* - */

  /* gets count of up steps required to get to common dir */
  basePath = _.strRemoveBegin( basePath, common );
  filePath = _.strRemoveBegin( filePath, common );

  let basePath2 = _.strRemoveBegin( _.strRemoveEnd( basePath, this.upToken ), this.upToken );
  let count = _.strCount( basePath2, this.upToken );

  if( basePath === this.upToken || !basePath )
  count = 0;
  else
  count += 1;

  if( !_.strBegins( filePath, this.upToken + this.upToken ) && common !== this.upToken )
  filePath = _.strRemoveBegin( filePath, this.upToken );

  /* prepends up steps */
  if( filePath || count === 0 )
  result = _.strDup( this.downUpToken, count ) + filePath;
  else
  result = _.strDup( this.downUpToken, count-1 ) + this.downToken;

  /* removes redundant slash at the end */
  if( _.strEnds( result, this.upToken ) )
  _.assert( result.length > this.upToken.length );

  if( result === '' )
  result = this.hereToken;

  if( _.strEnds( o.filePath, this.upToken ) && !_.strEnds( result, this.upToken ) )
  if( o.basePath !== this.rootToken )
  result = result + this.upToken;

  if( baseIsTrailed )
  {
    if( result === this.hereToken )
    result = this.hereToken;
    else if( result === this.hereUpToken )
    result = this.hereUpToken;
    else
    result = this.hereUpToken + result;
  }

  /* checks if result is normalized */

  _.assert( result.length > 0 );
  _.assert( result.lastIndexOf( this.upToken + this.hereToken + this.upToken ) === -1 );
  _.assert( !_.strEnds( result, this.upToken + this.hereToken ) );

  if( Config.debug )
  {
    let i = result.lastIndexOf( this.upToken + this.downToken + this.upToken );
    _.assert( i === -1 || !/\w/.test( result.substring( 0, i ) ) );
    if( o.resolving )
    _.assert
    (
        this.undot( this.resolve( o.basePath, result ) ) === this.undot( o.filePath )
      , () => o.basePath + ' + ' + result + ' <> ' + o.filePath
    );
    else
    _.assert
    (
        this.undot( this.join( o.basePath, result ) ) === this.undot( o.filePath )
      , () => o.basePath + ' + ' + result + ' <> ' + o.filePath
    );
  }

  return result;

  function beginsWithDown( filePath )
  {
    return filePath === self.downToken || _.strBegins( filePath, self.downUpToken );
  }

  function removeBeginDown( filePath )
  {
    if( filePath === self.downToken )
    return self.hereToken;
    return _.strRemoveBegin( filePath, self.downUpToken );
  }

}

_relative.defaults =
{
  basePath : null,
  filePath : null,
  resolving : 0,
}

//

/**
* Short-cut for routine relative {@link module:Tools/PathBasic.Path._relative _.path._relative}.
* Returns a relative path to `path` from an `relative`. Does not resolve paths {o.relative} and {o.path} before computation.
*
* @param {string|wFileRecord} relative Start path.
* @param {string|string[]} path Target path(s).
* @returns {string|string[]} Returns relative path as String or array of Strings.
* For more details please see {@link module:Tools/PathBasic.Path._relative _.path._relative}.
*
* @example
* let from = '/a';
* let to = '/b'
* _.path.relative( from, to );
* //'../b'
*
* @example
* let from = '/';
* let to = '/b'
* _.path.relative( from, to );
* //'./b'
*
* @example
* let from = '/a/b';
* let to = '/c'
* _.path.relative( from, to );
* //'../../c'
*
* @example
* let from = '/a';
* let to = './b'
* _.path.relative( from, to ); // throws an error paths have different type
*
* @example
* let from = '.';
* let to = '..'
* _.path.relative( from, to );
* //'..'
*
* @example
* let from = '..';
* let to = '..'
* _.path.relative( from, to );
* //'.'
*
* @example
* let from = '../a/b';
* let to = '../c/d'
* _.path.relative( from, to );
* //'../../c/d'
*
* @function relative
* @namespace Tools.path
*/

function relative_pre( routine, args )
{
  let o = args[ 0 ];
  if( args[ 1 ] !== undefined )
  o = { basePath : args[ 0 ], filePath : args[ 1 ] }

  _.routineOptions( routine, o );
  _.assert( args.length === 1 || args.length === 2 );
  _.assert( arguments.length === 2 );

  return o;
}

//

function relative_body( o )
{
  return this._relative( o );
}

relative_body.defaults = Object.create( _relative.defaults );

let relative = _.routineFromPreAndBody( relative_pre, relative_body );

//

function relativeCommon()
{
  let commonPath = this.common( filePath );
  let relativePath = [];

  for( let i = 0 ; i < filePath.length ; i++ )
  relativePath[ i ] = this.relative( commonPath,filePath[ i ] );

  return relativePath;
}

//

function _commonPair( src1, src2 )
{
  let self = this;

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert( _.strIs( src1 ) && _.strIs( src2 ) );

  let result = [];
  let first = pathParse( src1 );
  let second = pathParse( src2 );

  let needToSwap = first.isRelative && second.isAbsolute;
  if( needToSwap )
  {
    let tmp = second;
    second = first;
    first = tmp;
  }

  let bothAbsolute = first.isAbsolute && second.isAbsolute;
  let bothRelative = first.isRelative && second.isRelative;
  let absoluteAndRelative = first.isAbsolute && second.isRelative;

  if( absoluteAndRelative )
  {
    if( first.splitted.length > 3 || first.splitted[ 0 ] !== '' || first.splitted[ 2 ] !== '' || first.splitted[ 1 ] !== '/' )
    {
      debugger;
      throw _.err( 'Incompatible paths.' );
    }
    else
    return '/';
  }

  if( bothAbsolute )
  {
    commonGet();

    result = result.join( '' );

    if( !result.length )
    result = '/';
  }
  else if( bothRelative )
  {
    if( first.levelsDown === second.levelsDown )
    commonGet();

    result = result.join('');

    let levelsDown = Math.max( first.levelsDown,second.levelsDown );

    if( levelsDown > 0 )
    {
      let prefix = _.longFill( [], self.downToken, levelsDown );
      prefix = prefix.join( '/' );
      result = prefix + result;
    }

    if( !result.length )
    {
      if( first.isRelativeHereThen && second.isRelativeHereThen )
      result = self.hereToken;
      else
      result = '.';
    }
  }

  return result;

  /* - */

  function commonGet()
  {
    let length = Math.min( first.splitted.length, second.splitted.length );
    for( let i = 0; i < length; i++ )
    {
      if( first.splitted[ i ] === second.splitted[ i ] )
      {
        if( first.splitted[ i ] === self.upToken && first.splitted[ i + 1 ] === self.upToken )
        break;
        result.push( first.splitted[ i ] );
      }
      else
      {
        break;
      }
    }
  }

  /* */

  function pathParse( path )
  {
    let result =
    {
      isRelativeDown : false,
      isRelativeHereThen : false,
      isRelativeHere : false,
      levelsDown : 0,
    };

    result.normalized = self.normalize( path );
    result.splitted = split( result.normalized );
    result.isAbsolute = self.isAbsolute( result.normalized );
    result.isRelative = !result.isAbsolute;

    if( result.isRelative )
    if( result.splitted[ 0 ] === self.downToken )
    {
      result.levelsDown = _.longCountElement( result.splitted,self.downToken );
      let substr = _.longFill( [], self.downToken, result.levelsDown ).join( '/' );
      let withoutLevels = _.strRemoveBegin( result.normalized,substr );
      result.splitted = split( withoutLevels );
      result.isRelativeDown = true;
    }
    else if( result.splitted[ 0 ] === '.' )
    {
      result.splitted = result.splitted.splice( 2 );
      result.isRelativeHereThen = true;
    }
    else
    {
      result.isRelativeHere = true;
    }

    return result;
  }

  /* */

  function split( src )
  {
    return _.strSplitFast( { src,delimeter : [ '/' ], preservingDelimeters : 1,preservingEmpty : 1 } );
  }

  /* */

}

//

/*
qqq : teach common to work with path maps and cover it by tests
*/

function common()
{

  let paths = _.arrayFlatten( null, arguments );

  for( let s = 0 ; s < paths.length ; s++ )
  {
    if( _.mapIs( paths[ s ] ) )
    _.longBut_( paths, [ s, s + 1 ], _.mapKeys( paths[ s ] ) );
    // paths.splice( s, 1, _.mapKeys( paths[ s ] ) ); // Dmytro : can use it if unroll array returned by mapKeys()
  }

  _.assert( _.strsAreAll( paths ) );

  if( !paths.length )
  return null;

  paths.sort( function( a,b )
  {
    return b.length - a.length;
  });

  let result = paths.pop();

  for( let i = 0, len = paths.length ; i < len ; i++ )
  result = this._commonPair( paths[ i ], result );

  return result;
}

//

function rebase( filePath, oldPath, newPath )
{

  _.assert( arguments.length === 3, 'Expects exactly three arguments' );

  filePath = this.normalize( filePath );
  if( oldPath )
  oldPath = this.normalize( oldPath );
  newPath = this.normalize( newPath );

  if( oldPath )
  {
    let commonPath = this.common( filePath, oldPath );
    filePath = _.strRemoveBegin( filePath, commonPath );
  }

  filePath = this.reroot( newPath, filePath )

  return filePath;
}

// --
// exception
// --

function _onErrorNotSafe( prefix, filePath, level )
{
  _.assert( arguments.length === 3 );
  _.assert( _.strIs( prefix ) );
  _.assert( _.strIs( filePath ) || _.arrayIs( filePath ), 'Expects string or strings' );
  _.assert( _.numberIs( level ) );
  let args =
  [
    prefix + ( prefix ? '. ' : '' ),
    'Not safe to use file ' + _.strQuote( filePath ) + '.',
    `Please decrease safity level explicitly if you know what you do, current safity level is ${level}`
  ];
  return args;
}

let ErrorNotSafe = _.error_functor( 'ErrorNotSafe', _onErrorNotSafe );

// --
// fields
// --

let Parameters =
{
}

// --
// routines
// --

let Extension =
{

  // checker

  like,
  isElement,

  isSafe,
  isGlob,

  hasSymbolBase,

  // transformer

  prefixGet,
  name,
  fullName,

  ext,
  exts,
  withoutExt,
  changeExt,

  // joiner

  join,
  joinRaw,
  joinIfDefined,
  joinCross,
  reroot,
  resolve,
  joinNames,

  // stater

  current,

  // relator

  from,
  _relative,
  relative,
  relativeCommon,

  _commonPair,
  common,
  rebase,

  // fields

  ErrorNotSafe,

}

_.mapSupplement( Self, Parameters );
_.mapSupplement( Self.Parameters, Parameters );
_.mapSupplement( Self, Extension );

Self.Init();

// --
// export
// --

if( typeof module !== 'undefined' )
module[ 'exports' ] = Self;

})();
