library(sf)
library(rgdal)

# note: in order to calculate geodesic distance with sf
# the shapefile needs to be in geographic coordinate system
file0 <- st_read('C:/Users/ywx12/Desktop/PhD/RA/ProtectedLand/ProtConn_CALC/data/CO sample/reproj_sampfile.shp')
filesamp <- file0[1:10,]
file <- filesamp
tablepath <- 'C:/Users/ywx12/Desktop/PhD/RA/ProtectedLand/ProtConn_CALC/data/CO sample/test.csv'

num <- nrow(file)

li_d <- list()

k = 0

for(i in 1:num)
{
  for(j in 1:num)
  {
    if(i == j)
    {
    }
    else
    {
      dij <- st_distance(file[i, ], file[j, ], by_element = FALSE, which = "Great Circle")
      k = k + 1
      li_d[[k]] <- list(i, j, dij)
      # print(c(i, j, k))
    }
  }
}

df <- do.call(rbind.data.frame, li_d)
colnames(df) <- c("IN_FID", "NEAR_FID", "distance")

df_final <- df[df$distance <= 50000,]
write.csv(df_final, tablepath, row.names=FALSE)
