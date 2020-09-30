% Effect for training size:
% Results = cell(3, 25, 10); % PhoneChoice,UserCount,NFold
% Sizes = cell(3, 25, 10); % PhoneChoice,UserCount,NFold
ResultPath = 'TrainingResult/EnsembleResult.mat'
PhoneChoice = 2;
% for PhoneChoice = 2 : 3
    for UserCount = 23 : 25
        for NFold = 2 : 10
            try
                WatchOut_Train_Ensemble
            catch
                warning(['Error in: ' num2str(PhoneChoice) '; ' ...
                    num2str(UserCount) '; ' num2str(NFold)]);
            end
            save(ResultPath, 'Results', 'Sizes');
        end
    end
% end


% 
Results = cell(3, 25, 10); % PhoneChoice,UserCount,NFold
Sizes = cell(3, 25, 10); % PhoneChoice,UserCount,NFold
ResultPath = 'TrainingResult/DecisionTree.mat'
for PhoneChoice = 1 : 3
    for UserCount = 1 : 25
        for NFold = 2 : 10
            try
                WatchOut_Train_DecisionTree
            catch
                warning(['Error in: ' num2str(PhoneChoice) '; ' ...
                    num2str(UserCount) '; ' num2str(NFold)]);
            end
            save(ResultPath, 'Results', 'Sizes');
        end
    end
end


Results = cell(3, 25, 10); % PhoneChoice,UserCount,NFold
Sizes = cell(3, 25, 10); % PhoneChoice,UserCount,NFold
ResultPath = 'TrainingResult/SVM.mat'
for PhoneChoice = 1 : 3
    for UserCount = 1 : 25
        for NFold = 2 : 10
            try
                WatchOut_Train_SVM
            catch
                warning(['Error in: ' num2str(PhoneChoice) '; ' ...
                    num2str(UserCount) '; ' num2str(NFold)]);
            end
            save(ResultPath, 'Results', 'Sizes');
        end
    end
end

