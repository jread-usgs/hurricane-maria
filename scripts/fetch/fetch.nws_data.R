fetch.nws_data <- function(viz=as.viz("nws-data")){
  
  library(dplyr)
  library(xml2)
  library(httr)
  
  depend.data <- readDepends(viz)
  checkRequired(depend.data, c('sites','nws'))
  sites <- depend.data[["sites"]]
  
  sites$flood.stage <- NA
  sites$flood.stage.units <- NA

  nws_node <- "primary"

  forecastDF <- data.frame()
  
  for(i in sites$NWS){
    url.site <- paste0("https://water.weather.gov/ahps2/hydrograph_to_xml.php?gage=",i,"&output=xml")
    print(i)
    return_list <- GET(url.site)
    returnedDoc <- content(return_list,encoding = "UTF-8")
    nws.site <- xml_root(returnedDoc)
    sigstages <- xml_find_all(nws.site, "sigstages")
    
    if(length(sigstages) > 0){
      sites$flood.stage[which(sites$NWS %in% i)] <- as.numeric(xml_text(xml_find_all(sigstages, "flood")))
      sites$flood.stage.units[which(sites$NWS %in% i)] <- xml_attr(xml_find_all(sigstages, "flood"),"units")
    }
    
    forecast <- xml_find_all(nws.site, "forecast")
    forecast_children <- xml_children(forecast)
    if(length(forecast_children) == 0) {
      #not all sites have forecasts
      next
    } else {
      time_nodes <- xml_find_all(forecast_children, "valid")
      value_nodes <- xml_find_all(forecast_children, nws_node)
      assertthat::assert_that(length(unique(xml_attr(value_nodes, "units"))) == 1)
      forecast_site <- data.frame(site = i,
                                  dateTime = xml_text(time_nodes),
                                  tz = xml_attr(time_nodes, "timezone"),
                                  forecast_vals = xml_text(value_nodes)
      )
      forecastDF <- bind_rows(forecastDF, forecast_site)
    }
  }
  
  sites <- sites %>% filter(!is.na(flood.stage)) %>% select(site_no, flood.stage)
  
  saveRDS(sites, file=viz[['location']])

}

fetchTimestamp.nws_data <- neverCurrent
