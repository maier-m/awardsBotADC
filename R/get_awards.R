#' Get Awards Database
#' 
#' Run this code to get the awards database with updated awards
#'
#' @param database_path (character) path to file containing database
#' @param n_days (numeric) number of days to search backwards from the current day to get new awards 
#'
#' @export
get_awards <- function(database_path, n_days) {
  
  ## get old awards ##
  
  ## get database (if no database exists, for example during an initial setup return a blank data frame)
  adc_nsf_awards <- tryCatch({
    adc_nsf_awards <- utils::read.csv(database_path)
    adc_nsf_awards <- data.frame(apply(adc_nsf_awards, 2, as.character), stringsAsFactors = FALSE) # force all fields into characters
  }, error = function(e) {
    ## set up columns for database
    names_database <- c("awardee",
                        "date",
                        "expDate",
                        "fundProgramName",
                        "id",
                        "piEmail",
                        "piFirstName",
                        "piLastName",
                        "piPhone",
                        "poName",
                        "startDate",
                        "title",
                        "rtTicket",
                        "piORCID",
                        "contact_initial",
                        "contact_3mo",
                        "contact_1mo",
                        "contact_1wk",
                        "adcPids")
    ## create a new data frame
    adc_nsf_awards <- data.frame(matrix(ncol = length(names_database), nrow = 0))
    colnames(adc_nsf_awards) <- names_database
    adc_nsf_awards
  })
  
  ## get new awards ##
  
  ## initiallize dates
  format <- "%m/%d/%Y"
  to_date <- Sys.Date()
  from_date <- to_date - n_days
  to_date <- format(to_date, format)
  from_date <- format(from_date, format)
  
  ## get new awards from NSF API
  new_nsf_awards <- datamgmt::get_awards(from_date = from_date, to_date = to_date)
  new_nsf_awards <- new_nsf_awards[!(new_nsf_awards$id %in% adc_nsf_awards$id), ]
  
  ## combine awards
  adc_nsf_awards <- suppressWarnings(dplyr::bind_rows(adc_nsf_awards, new_nsf_awards))
  
  ## deal with dates ##
  
  ## this is needed if someone opens the database in excel and saves it as a csv, the dates format changes in this case
  ## Also NSF dates are m-d-y whereas R dates are y-m-d
  ## potentially there is a more elegant solution than the one here
  ## Forcing date columns to y-m-d
  
  is_date <- which(colnames(adc_nsf_awards) %in% c("date",
                                                   "expDate",
                                                   "startDate",
                                                   "contact_initial",
                                                   "contact_3mo",
                                                   "contact_1mo",
                                                   "contact_1wk"))
  
  adc_nsf_awards[, is_date] <- apply(adc_nsf_awards[, is_date], c(1,2), function(x){
    if (!is.na(x)) {  
      
      ## if not NA try to reformat date from m-d-y to y-m-d
      ## may need to test edge cases to ensure this always works
      tryCatch({
        paste0(lubridate::mdy(x))
      }, warning = function(w) {
        x
      })
      
    } else {
      NA
    }
  })
  
  ## write output
  return(adc_nsf_awards)
}

