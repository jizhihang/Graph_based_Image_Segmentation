% this functions calculates the result of image segmentation using
% recursively two-way cuts
% the inputs are: image, mask, criteria, sigma1, sigmax
% the ourputs are: the result of segmentation
function calCuts(image,mask,criteria,sigma1,sigmax)

OnesinMask = length(find(mask == 1));

[height, width] = size(image); 

% W = sparse(height*width,height*width);
W = getW(image,mask,sigma1,sigmax);
d = sum(W,2);

% computer diagonal matrix
D = spdiags(d,0,OnesinMask,OnesinMask);
d1 = d.^(-1/2);
D1 = spdiags(d1,0,OnesinMask,OnesinMask);

% computer eigenvalues and vectors
A = D1*(D-W)*D1;
[V,D_value] = eigs(A,9,'SM');
eigenValues = diag(D_value);

%get the vector corresponding to the second smallest eigenvalue
SMVector = V(:,2); 
Max_SMV = max(SMVector);
Min_SMV = min(SMVector);

SplitNum = 20;
SplitP = Min_SMV:(Max_SMV-Min_SMV)/(SplitNum-1):Max_SMV;
NCut = zeros(SplitNum,1);
% calculate the current NCut
for i = 1:SplitNum
    Threshold = SplitP(i);
    PartOne = SMVector;

    PartOne(PartOne>=Threshold) = 1;
    PartOne(PartOne<Threshold) = 0;

    [x_NZ,y_NZ,s_NZ] = find(W);
    TheOnes = xor(PartOne(uint16(x_NZ)),PartOne(uint16(y_NZ)));
    CutAB = sum(s_NZ(TheOnes));

    assocAV = sum(PartOne.*d);
    assocBV = sum(~PartOne.*d);
    NCut(i) = CutAB/assocAV + CutAB/assocBV;
end

% to see if the Ncut has reached the criteria, if not, recursively call hte
% calCuts function
if min(NCut)<criteria
    
    index = find(NCut == min(NCut));
    nextThreshold = SplitP(index(1));
    disp('Split Point: ');disp(nextThreshold);

    nextPartOne = SMVector;
    ImageVector = reshape(image,[],1);

    nextPartOne(nextPartOne>=nextThreshold) = 1;
    nextPartOne(nextPartOne<nextThreshold) = 0;

    nextPartOneMask = zeros(1,height*width);
    nextPartOneMask(mask == 1) = nextPartOne';

    nextImageOneVector = ImageVector.*nextPartOneMask';
    nextImageOne = reshape(nextImageOneVector,height,width);
    figure; imshow(nextImageOne);
    Mask1 = nextPartOneMask;    

    nextPartTwoMask = zeros(1,height*width);
    nextPartTwoMask(mask == 1) = ~nextPartOne;
    nextImageTwoVector = ImageVector.*nextPartTwoMask';
    nextImageTwo = reshape(nextImageTwoVector,height,width);
    figure; imshow(nextImageTwo);
    Mask2 = nextPartTwoMask;
    
    calCuts(image,Mask1,criteria,sigma1,sigmax);
    calCuts(image,Mask2,criteria,sigma1,sigmax);

end