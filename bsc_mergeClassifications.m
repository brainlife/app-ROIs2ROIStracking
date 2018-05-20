function [classification] = bsc_mergeClassifications(baseClassification,classificationAdd)

baseNames=baseClassification.names;
baseNameNum=length(baseClassification.names);

addNames=classificationAdd.names;
addNameNum=length(classificationAdd.names);

presumeNameNum=baseNameNum+addNameNum;

uniqueNamesTotal=unique(horzcat(baseNames,addNames));
uniqueNamesLength=length(uniqueNamesTotal);

classification.names=[];
classification.index=zeros(length(baseClassification.index)+length(classificationAdd.index),1);

if uniqueNamesLength==presumeNameNum
    %hyper inelegant, guarenteed to cause problems.
    classification.names=horzcat(baseNames,addNames);
    classificationAdd.index(classificationAdd.index>0)=classificationAdd.index(classificationAdd.index>0)+baseNameNum;
    classification.index=vertcat(baseClassification.index,classificationAdd.index);
    
    %     addIndex=[classificationAdd.index]+[classificationAdd.index>0] *baseNameNum;
    %     classification.index(classificationAdd.index>0)=0;
    %     if sum(size(addIndex,1)==size(baseClassification.index,1))==2
    %     classification.index=horzcat(baseClassification.index+addIndex;
    %     else
    %         classification.index=baseClassification.index+addIndex';
    %     end
else
    
    classification.names=uniqueNamesTotal;
    for iNames=1:length(classification.names)
        baseNameIndex=find(strcmp(baseNames,uniqueNamesTotal{iNames}));
        addNameIndex=find(strcmp(addNames,uniqueNamesTotal{iNames}));
        
        if ~isempty(baseNameIndex)
            baseIndexes=find(baseClassification.index==baseNameIndex);
        else
            baseIndexes=[];
        end
        
        if ~isempty(addNameIndex)
            addIndexes=find(classificationAdd.index==addNameIndex);
        else
            addIndexes=[];
        end
        
        classification.index(baseIndexes)=iNames;
        classification.index(addIndexes+length(baseClassification.index))=iNames;
        
    end
end
    