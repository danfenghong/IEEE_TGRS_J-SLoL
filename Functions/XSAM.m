function r=XSAM(re_A,A)
[D,N]=size(A);
ss=zeros(N,1);
for i=1:N
    ss(i,1)=acos(1-pdist2(re_A(:,i)',A(:,i)','cosine'));
%     ss(i,1)=acos((re_A(:,i)'*A(:,i))/(norm(A(:,i))*norm(re_A(:,i))));%acos(1-pdist2(re_A(:,i)',A(:,i)','cosine'));
end
% r=mean(ss*180/pi);
r=mean(ss);