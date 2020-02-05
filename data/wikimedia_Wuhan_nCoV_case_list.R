# clone of https://commons.wikimedia.org/wiki/File:2019-nCoV_in_Wuhan.svg
# date: 24-Jan-2020 12:10pm PST

Lines <- "Date	Type	Cases
# http://wjw.wuhan.gov.cn/front/web/showDetail/2019123108989
# https://web.archive.org/web/20200120044512/http://wjw.wuhan.gov.cn/front/web/showDetail/2019123108989
2019-12-31	Normal	20
2019-12-31	Severe	7

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020010309017
# https://web.archive.org/web/20200120044756/http://wjw.wuhan.gov.cn/front/web/showDetail/2020010309017
2020-01-03	Normal	33
2020-01-03	Severe	11

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020010509020
# https://web.archive.org/web/20200114082052/http://wjw.wuhan.gov.cn/front/web/showDetail/2020010509020
2020-01-05	Normal	52
2020-01-05	Severe	7

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020011109035
# https://web.archive.org/web/20200113213431/http://wjw.wuhan.gov.cn/front/web/showDetail/2020011109035
2020-01-11	Normal	31
2020-01-11	Severe	7
2020-01-11	Death	1
2020-01-11	Released	2

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020011209037
# https://web.archive.org/web/20200113062247/http://wjw.wuhan.gov.cn/front/web/showDetail/2020011209037
2020-01-12	Normal	27
2020-01-12	Severe	7
2020-01-12	Death	1
2020-01-12	Released	6

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020011309038
# https://web.archive.org/web/20200113194045/http://wjw.wuhan.gov.cn/front/web/showDetail/2020011309038
2020-01-13	Normal	27
2020-01-13	Severe	6
2020-01-13	Death	1
2020-01-13	Released	7

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020011409039
# https://web.archive.org/web/20200114142353/http://wjw.wuhan.gov.cn/front/web/showDetail/2020011409039
2020-01-14	Normal	27
2020-01-14	Severe	6
2020-01-14	Death	1
2020-01-14	Released	7

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020011509046
# https://web.archive.org/web/20200115155701/http://wjw.wuhan.gov.cn/front/web/showDetail/2020011509046
2020-01-15	Normal	27
2020-01-15	Severe	6
2020-01-15	Death	1
2020-01-15	Released	7

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020011609057
# https://web.archive.org/web/20200120051422/http://wjw.wuhan.gov.cn/front/web/showDetail/2020011609057
2020-01-16	Normal	22
2020-01-16	Severe	5
2020-01-16	Death	2
2020-01-16	Released	12

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020011809064
# https://web.archive.org/web/20200120051747/http://wjw.wuhan.gov.cn/front/web/showDetail/2020011809064
2020-01-17	Normal	23
2020-01-17	Severe	5
2020-01-17	Death	2
2020-01-17	Released	15

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020011909074
# https://web.archive.org/web/20200120052005/http://wjw.wuhan.gov.cn/front/web/showDetail/2020011909074
2020-01-18	Normal	33
2020-01-18	Severe	8
2020-01-18	Death	2
2020-01-18	Released	19

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020012009077
# https://web.archive.org/web/20200120052215/http://wjw.wuhan.gov.cn/front/web/showDetail/2020012009077
2020-01-19	Normal	126
2020-01-19	Severe	35
2020-01-19	VerySevere	9
2020-01-19	Death	3
2020-01-19	Released	25

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020012109083
# https://web.archive.org/web/20200120204623/http://wjw.wuhan.gov.cn/front/web/showDetail/2020012109083
2020-01-20	Normal	125
2020-01-20	Severe	35
2020-01-20	VerySevere	9
2020-01-20	Death	4
2020-01-20	Released	25

# http://wjw.wuhan.gov.cn/front/web/showDetail/2020012109085
# https://web.archive.org/web/20200121101138/http://wjw.wuhan.gov.cn/front/web/showDetail/2020012109085
2020-01-21	Normal	164
2020-01-21	Severe	51
2020-01-21	VerySevere	12
2020-01-21	Death	6
2020-01-21	Released	25
"

df <- read.table(textConnection(Lines), header = TRUE)
df$Type <- factor(df$Type, levels=c("Death", "VerySevere", "Severe", "Normal", "Released") )
df$Date <- as.Date( df$Date, '%Y-%m-%d') # https://stackoverflow.com/a/4844931/2603230

require(ggplot2)
library(viridis)
library(scales)
mygraph <- ggplot(data = df, aes(x=Date, y=Cases, label=Cases, fill=Type, group=Type)) +
  geom_bar(position="stack", stat="identity") +
  geom_text(data=subset(df, Cases != 0), position = position_stack(vjust = 0.5), size = 2.5) +
  scale_x_date(date_breaks = "days", labels = date_format("%Y-%m-%d")) +
  scale_fill_manual("Legend", labels = c("Death", "Critical", "Serious", "Fair", "Released"), values = c("Normal" = "#FFE5B4", "Severe" = "orange", "VerySevere" = "red", "Death" = "brown", "Released" = "lightgray")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "2019-nCoV in Wuhan, China",
       subtitle = "As of 2020-01-20 24:00",
       caption = "Data Source: Wuhan Municipal Health Commission (listed in the source code)\nNote: The condition “Critical” was added on 2020-01-19.",
       x = "Report Date",
       y = "Number of Cases")
mygraph

write.table(df, file='./data/wikimedia_Wuhan_nCoV_case_list_24-Jan-2020.csv', sep=',',row.names=FALSE)