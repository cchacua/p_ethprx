data<-read.csv('../input/nationality_all_names.csv')

#Uncentered correlation
# https://www.rdocumentation.org/packages/philentropy/versions/0.3.0/topics/lin.cor  
# https://github.com/HajkD/philentropy  

colnames(data)
data2<-data[,13:ncol(data)]
data$totalp<-rowSums(data[,13:ncol(data)])

summary(data$totalp)
View(data[data$totalp==1,])

v1<-c(0.5, 0.4, 0.1,   0, 0)
v2<-c(0.9, 0.1, 0,     0, 0)
v3<-c(0.2, 0.2, 0.2, 0.2, 0.2)
v4<-c(0.6, 0.4,   0,   0, 0)
v5<-c(  0,   0, 0.1, 0.5, 0.4)

v<-data.frame(v1v2=dist.diversity(rbind(v1,v2), p = 2, unit = "log2"),
              v1v3=dist.diversity(rbind(v1,v3), p = 2, unit = "log2"),
              v1v4=dist.diversity(rbind(v1,v4), p = 2, unit = "log2"),
              v1v5=dist.diversity(rbind(v1,v5), p = 2, unit = "log2")
              )

v$v1v4v1v2<-abs(v$v1v4-v$v1v2)
v$v1v4v1v3<-abs(v$v1v4-v$v1v3)
summary(v)
View(v[v$v1v5<v$v1v3 && v$v1v3<v$v1v2,])
View(v[v$v1v3<v$v1v2 && v$v1v2<v$v1v4,])
View(v[v$v1v3<v$v1v2,])

View(v[v$v1v5>v$v1v3 && v$v1v3>v$v1v2,])


p1 <- plot_ly(
  v, x = ~v1v4, y = ~v1v2,
  # Hover text:
  text = ~paste("Name: ", rownames(v))
) %>% layout(xaxis = list(range = c(0,2)), yaxis = list(range = c(0,2)))

htmlwidgets::saveWidget(p1, "v1v4_v1v2.html")


p2 <- plot_ly(
  v, x = ~v1v4, y = ~v1v3,
  # Hover text:
  text = ~paste("Name: ", rownames(v))
) %>% layout(xaxis = list(range = c(0,2)), yaxis = list(range = c(0,2)))

htmlwidgets::saveWidget(p2, "v1v4_v1v3.html")

p3 <- plot_ly(
  v, x = ~v1v2, y = ~v1v3,
  # Hover text:
  text = ~paste("Name: ", rownames(v))
) %>% layout(xaxis = list(range = c(0,2)), yaxis = list(range = c(0,2)))

htmlwidgets::saveWidget(p3, "v1v2_v1v3.html")

######################################################################################################################
