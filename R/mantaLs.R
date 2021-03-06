# Roxygen Comments mantaLs
#' Lists, searches, filters, sorts and formats Manta directory listings.
#'
#' Used for getting disk size, number of objects, number of subdirectories.
#' Searching for filenames with regular expressions (using R grep). 
#' Sorting listings by filename, time, or size.
#'
#' @param mantapath character, optional. Current subdirectory set by \code{mantaSetwd}
#' is used, otherwise specify full Manta path to subdirectory. Supports \code{~~} 
#' expansion to your Manta username, e.g. \code{"~~/public"} and UTF-8 encoded characters.
#'
#' @param grepfor character optional. Regular expression for \code{grep} name search.
#' Uses R regexps, N.B. use  \code{"[.]txt"}, not
#' \code{"*.txt"} to match filename extensions.
#'
#' @param json optional. Input saved JSON data from \code{mantaLs(l = 'json')} 
#' used for reprocessing previously retrieved listings. Include previously specified
#' mantapath if you wish to recover true paths.
#'
#' @param l character optional.\cr
#' Specifies listing output format by \code{'names', 'l', 'paths', 
#' 'URL', 'n', 'du', 'R', 'Rraw', 'URL', 'json'.}.\cr
#' \code{'names'} returns object/directory names.\cr
#' \code{'l'} is a long unix ls -o  style of directory listing.\cr
#' \code{'paths'} is a listing of full Manta object pathnames.\cr
#' \code{'n'} is the number of entries in the directory only.\cr
#' \code{'du'} is the number of bytes used by objects (not counting redundancy levels!).\cr
#' \code{'R'} is normalized R structures from JSON with size = 0 for directories, 
#' \code{mtime} in R time format.\cr
#' \code{'URL'} is the browser format URL for objects, applies to \code{~~/public} objects only.\cr
#' \code{'Rraw'} is R struct unparsed, unsorted, unnormalized, 
#'  can convert back to json with \code{toJSON}.\cr
#' \code{'json'} is exactly what the server replies - sorting/filtering are not applied.\cr
#' 
#' @param items character optional. \code{'a'} for all, \code{'d'} for directory, \code{'o'} for object. 
#' 
#' @param sortby character, optional. Specify \code{'none'}, \code{'name'}, \code{'time'}, or \code{'size'}.
#' 
#' @param decreasing logical, optional. Argument passed to R \code{order} for sorting. 
#' 
#' @param ignore.case logical, optional. Argument passed to R \code{grep} for searching.
#' 
#' @param perl logical, optional. Argument passed to R \code{grep} for searching. 
#' 
#' @param verbose logical, optional. Verbose HTTPS \code{RCurl} data output on Unix.
#'
#' @param internal logical, Internal use by mantaFind.
#'
#' @keywords Manta
#'
#' @family mantaLs
#'
#' @seealso \code{\link{mantaFind}}
#'
#' @examples
#' \dontrun{
#' ## List names of  all objects stored in the directory 
#' ## specified by mantaSetwd(),
#' mantaLs()
#'
#' ## List all objects ending in .jpg or .JPG
#' ## in your Manta ~~/public/images directory,
#' ## Show a UNIX-like result sorted by file size:
#' mantaLs("~~/public/images", l = 'l', items = 'o', grepfor = "[.]jpg",
#' ignore.case = TRUE, sortby = 'size')
#'
#' ## Download all objects in current Manta directory, non recursive find:
#' #mantaGet(mantaLs.paths(items = 'o'))
#'
#' }
#'
#' @export
mantaLs <-
function(mantapath, grepfor, json, l = 'names', items = 'a', sortby = 'none', 
          decreasing = FALSE, ignore.case = FALSE, perl = FALSE, verbose = FALSE,
          internal = FALSE) {
## TODO stat mantapath if entered to see if it is an object, so don't send a GET object...

  # If this is the first export function called in the library
  if (manta_globals$manta_initialized == FALSE) {
    mantaInitialize(useEnv = TRUE)
  }


  if (missing(mantapath)) {
      mantapath <- mantaGetwd()
  }

  path_enc <- mantaPath(mantapath)

  validl <- c('names', 'l', 'paths', 'n', 'du', 'URL', 'R', 'Rraw', 'json')
  validsortby <- c('none', 'name', 'time', 'size')
  validitems <- c('a', 'd', 'o')
  
  if (is.na(match(l,validl))) stop("mantaLs Invalid l='",l,"' argument, try help(mantaLs)\n") 
  if (is.na(match(sortby,validsortby))) stop("mantaLs Invalid sortby='",sortby,"' argument, try help(mantaLs)\n") 
  if (is.na(match(items,validitems))) stop("mantaLs Invalid items='",items,"' argument, try help(mantaLs)\n") 

  if (l == 'URL') {
    # must begin with /$MANTA_USER/public
    lead <- paste("/", manta_globals$manta_user, "/public", sep="")
    if  (is.na(charmatch(lead, path_enc))) {
       stop("mantaLs Invalid Manta subdirectory for public URLs - must be in ", lead)
    }
  }


  if (missing(json)) { 

#cat(path_enc,"- is the path to list\n")
    method <- "GET"

    limit <- manta_globals$manta_defaults$max_limit

#cat(method, "- is the method used\n")

    if (internal == FALSE) { # User calling mantaLs, not mantaFind
      bunyanClearSetpoint()
      bunyanSetpoint()
    }

#cat(limit, "-is the limit used\n")
 
    if (path_enc != "") {
      dir <- mantaAttempt(action=path_enc, method=method, json=TRUE, limit=limit, verbose=verbose)
    } else {
      msg <- paste("mantaLs: path to list is invalid ", mantapath,"\n",sep="")
      bunyanLog.error(msg) 
      stop(msg)
    }

#cat("\n\n first HTTP call done\n")

    setsize <- 0 

    if (!is.na(dir$count)) {
      setsize <- dir$count
    }
  
#cat(setsize, "- is setsize\n")

    setsofar <- length(dir$lines)

#cat(setsofar, "- is setsofar\n")

    entries <- dir$lines

    if (setsize == 0)
      return("")

    if (setsofar == 0) 
      return("")

  
   # marker is the object name in the directory to begin from that point
   # limit changes the maximum number of entries - mantaSetLimits has default


    while (setsofar < setsize) {  # get more entries
      # here job listings may fail on $name - use $id ??
      marker_line <- fromJSON(entries[length(entries)])
      if (mode(marker_line) == "character")  marker_line <- as.vector(marker_line, mode="list")
      marker <- marker_line$name   
#cat("\n\nIn while\n")
#cat(marker, "- is marker\n")
      dir <- mantaAttempt(action=path_enc, method=method, json=TRUE, limit=limit, marker=marker, verbose=verbose)
      entries <- c(entries, dir$lines[-1]) # concat, remove the redundant marker entry 
      setsofar <- length(entries) 
#cat(setsofar,":",setsize," - are setsofar:setsize")
    }
    if (internal == FALSE) { # User calling mantaLs, not mantaFind
      errorcount <- bunyanTracebackN(level='ERROR')
      if (errorcount > 0) {
        msg <- paste("mantaLs: ",errorcount, " transmission Errors encountered, use bunyanTraceback(level='ERROR') to view\n")
        bunyanLog.info(msg)
        cat(msg)
      }
   }
 } else { # Input is previously retrieved JSON listing, so use that
   entries <- json
 }

#cat(l," - is format to apply\n")


  ## These are the raw unfiltered/unsorted formats which return here

  switch(l,
    json={
    # JSON data as received from server, sorting/filtering  ignored
    # these are returned as is
      return(entries)
    },
    Rraw={
    # straight reversible fromJSON transorm of server data
    # sorting/filtering is ignored, returned as is
      return(lapply(entries,fromJSON))
    }
  )


### Filtered/Formated/Sorted Output

  # R normalize, size setting and time parsing callback
  Rstyle <- function(line) {
    line <- fromJSON(line)
    # this gives mixed mode R for directories, objects, so we normalize
    if (mode(line) == "character") {
      line <- as.vector(line, mode="list")
    }
    if (is.na(charmatch("size",names(line)))) {
      line$size <- 0
    }
    # parse the timestamp into R
    time <- strptime(line$mtime, tz = "GMT", "%Y-%m-%dT%H:%M:%OS")
    # Replace mtime with parsed R time                                  
    line$mtime <- time                                 
    return(line)
  }

  # Parse entries into Rstyle to normalize
  entries <- lapply(entries, Rstyle)
  
  # Regexp of names - strongest filter first...
  if (!missing(grepfor)) {
      names <- unlist(lapply(entries, mantagetnames))
      entries <- entries[grep(grepfor, names, ignore.case=ignore.case, perl=perl )]
  }

  if (length(entries) == 0) { return("") } # nothing left after filter

  # Directory entry type filter callback
  filtertype <- function(line) {
    if (items == "a") { 
      return(line) 
    }
    if (items == "d") {
      if (line$type == "directory") {
        return(line)
      }   
    }
    if (items == "o") {
      if (line$type == "object") {
        return(line)
      }
    }
  }

  # Filter by object or diretory 
  entries <- lapply(entries, filtertype)
  entries <- entries[!sapply(entries, is.null)]

  if (length(entries) == 0) { return("") }  # nothing left after filter

  # Full pathname callback
  pliststyle <- function(line) {
    if (!is.na(charmatch("name",names(line)))) {
     return(paste(curlUnescape(path_enc), "/", line$name, sep=""))
    }
    if (!is.na(charmatch("id",names(line)))) {
     return(paste(curlUnescape(path_enc), "/", line$id, sep=""))
    }
  } 

  urlstyle <-function(line) {
    return(paste(manta_globals$manta_url,pliststyle(line),sep=""))
  }

  switch(l,
    R={
      lines <- entries
    },
    names={
      lines <- lapply(entries, mantaliststyle)
    },
    l={
      lines <- lapply(entries, mantaunixstyle)
    },
    URL={
      lines <- lapply(entries, urlstyle)
    },
    paths={
      lines <- lapply(entries, pliststyle)
    },
    n={ 
    # return number of entries
      return(length(entries))
    },
    du={
    # return disk size utilized of entries, in bytes
    # not factoring in number of reduncant copies
      return(sum(unlist(lapply(entries, mantadusize))))
    }
  ) 


### Sorted/filtered R entries or formatted lines

  switch(sortby,
    none={
    },
    name={
      names <- lapply(entries, mantagetnames)
      lines <- lines[order(unlist(names), decreasing = decreasing)]
    },
    size={
      sizes <- lapply(entries, mantagetsize)
      lines <- lines[order(unlist(sizes), decreasing = decreasing)]
    },
    time={
      times <- lapply(entries, mantagettime)
      times <- do.call(c,times) # Keeps the  R time structure for sorting...
      lines <- lines[order(times, decreasing = decreasing)]
    }
  )

 if (l == "R") {  # don't flatten the R 
  return(lines) 
 }
 else { # flatten the lines
    return(do.call(c,lines))
 }

}


