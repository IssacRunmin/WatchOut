% load('SVM_WORKSPACE_06091101_6STATES.mat');
% Beta Bias Mu Sigma
% Bias:     1 ¡Á 1 double
% Beta:     69 ¡Á 1 double
% Mu:       1 ¡Á 69 double
% Sigma:    1 ¡Á 69 double
TempScore = ((binary_tree.X - binary_tree.Mu) ./ binary_tree.Sigma) * binary_tree.Beta + binary_tree.Bias; 
[Predict_Labels,~,~] = predict(binary_tree,binary_tree.X);
sum(((TempScore > 0)  + 1) ~= Predict_Labels);
Len  = length(binary_tree.Beta);
file = fopen('SVM_PARAMETER.dat','w');
% for i = 1 : Len
% fwrite(file,binary_tree.Beta,'double');
% end
fwrite(file,binary_tree.Bias,'double');
fwrite(file,binary_tree.Beta,'double');
fwrite(file,binary_tree.Mu,'double');
fwrite(file,binary_tree.Sigma,'double');
fwrite(file,AdvancedTree.Bias,'double');
fwrite(file,AdvancedTree.Beta,'double');
fwrite(file,AdvancedTree.Mu,'double');
fwrite(file,AdvancedTree.Sigma,'double');
fwrite(file,ESTTR,'double');
fwrite(file,ESTEMIT,'double');
fclose(file);
file = fopen('SVM_PARAMETER.dat','r');
A = fread(file,'double');
% sum(A(2:70) ~= binary_tree.Beta)
A(end - 6:end)
fclose(file);