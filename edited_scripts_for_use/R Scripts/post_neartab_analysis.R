library(sf)


node_path = 'C:/Users/wyang80/Desktop/ProtConn/Node_States'
out_path = 'C:/Users/wyang80/Desktop/ProtConn/Node_States/csv' 
neartab_gdb = 'C:/Users/wyang80/Desktop/ProtConn/STATES/Neartab_States.gdb'
dir.create(out_path)
li_files <- as.list(list.files(path = node_path))
li_txt <- li_files[grepl("\\.txt", li_files)]


all_near_tab <- data.frame(matrix(ncol = 6, nrow = 0))
colnames(all_near_tab) <- c('IN_FID', 'NEAR_FID', 'NEAR_DIST', 'NEAR_RANK', 'IN_ORIG_FID', 'NEAR_ORIG_FID')

all_node_tab <- data.frame(matrix(ncol = 4, nrow = 0))
colnames(all_node_tab) <- c('ifPA', 'STATEFP', 'AREA_GEO', 'ORIG_FID')


for (i in li_txt){
  nodetab_path = file.path(node_path, i)
  new_node_filename = gsub('txt', 'csv', i)
  node_tab <- read.table(file = nodetab_path, sep=',', header = TRUE)
  merge_tab <- node_tab[c('ORIG_FID', 'nodeID')]
  mergenode_tab <- node_tab[c('ifPA', 'STATEFP', 'AREA_GEO', 'ORIG_FID')]

  
  all_node_tab <- rbind(all_node_tab, mergenode_tab)
  
  write.csv(node_tab, file = file.path(out_path, new_node_filename))
  print(new_node_filename)
  
  
  
  layer_filename = paste('Near_tab_',gsub('.txt', '', i), sep = '')
  near_tab <- sf::st_read(dsn = neartab_gdb, layer = layer_filename)
  new_layer_filename = paste(layer_filename, '.csv')
  
  merged_neartab_infid <- merge(x = near_tab, y = merge_tab, by.x = 'IN_FID', by.y = 'nodeID', all.x = TRUE)
  colnames(merged_neartab_infid)[5] <- 'IN_ORIG_FID'
  
  merged_neartab_innearfid <- merge(x = merged_neartab_infid, y = merge_tab, by.x = 'NEAR_FID', by.y = 'nodeID', all.x = TRUE)
  colnames(merged_neartab_innearfid)[6] <- 'NEAR_ORIG_FID'
  
  all_near_tab <- rbind(all_near_tab, merged_neartab_innearfid)

  write.csv(merged_neartab_innearfid, file = file.path(out_path, new_layer_filename))
  print(new_layer_filename)
}


deduped_node_tab <- unique(all_node_tab)
deduped_near_tab <- unique(all_near_tab)

write.csv(deduped_node_tab, file = file.path(out_path, 'deduped_node_tab_STATES.csv'))
write.csv(deduped_near_tab, file = file.path(out_path, 'deduped_near_tab_STATES.csv'))


