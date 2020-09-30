function [en] = getEntropy( data,len,scale )
%GETENTROPY 此处显示有关此函数的摘要
%   data is a sorted 1-dimensional array
Pdata=round(data/scale);
j=1;
forpro(1)=1;
for i=2:len
    if(Pdata(i)==Pdata(i-1))
        forpro(j)=forpro(j)+1;
    else 
        j=j+1;
        forpro(j)=1;
    end
end
en=0;
for i=1:j
    en=en+forpro(i)/len*log(forpro(i)/len);
end
end

