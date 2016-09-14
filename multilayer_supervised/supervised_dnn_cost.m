function [ cost, grad, pred_prob] = supervised_dnn_cost( theta, ei, data, labels, pred_only)
%SPNETCOSTSLAVE Slave cost function for simple phone net
%   Does all the work of cost / gradient computation
%   Returns cost broken into cross-entropy, weight norm, and prox reg
%        components (ceCost, wCost, pCost)

%% default values
po = false;
if exist('pred_only','var')
  po = pred_only;
end;

%% reshape into network
stack = params2stack(theta, ei);
numHidden = numel(ei.layer_sizes) - 1;
hAct = cell(numHidden+1, 1);
gradStack = cell(numHidden+1, 1);

m = size(data, 2);
num_classes = ei.layer_sizes(end);

%% forward prop
for i = 1:length(ei.layer_sizes)
	if(i == 1) input = data; else input = hAct{i-1}; end;

	hAct{i} = stack{i}.W*input + repmat(stack{i}.b, 1, m);

	% The last layer goes through a softmax
	if(i < length(ei.layer_sizes))
		switch ei.activation_fun
					 case 'logistic'
						 hAct{i} = sigmoid(hAct{i});
		end
	end
end

pred_prob = exp(hAct{end}) ./ (repmat( sum(exp(hAct{end})), num_classes, 1));

																	
%% return here if only predictions desired.
if po
  cost = -1; ceCost = -1; wCost = -1; numCorrect = -1;
  grad = [];  
  return;
end;

%% compute cost
ceCost = - sum( sum( log(pred_prob) .* eye(num_classes)(:,labels) ) );

					
% dL_di is called delta in the notes as well as some of the literature.
% I prefer dL_di because this name is more suggestive- these are the
% derivatives of the loss wrt input at a node
dL_di = cell(length(ei.layer_sizes), 1);

dL_di{end} = -( eye(num_classes)(:,labels) - pred_prob );


for i=(length(ei.layer_sizes) - 1):-1:1
	dL_di{i} = stack{i+1}.W'*dL_di{i+1};

	switch ei.activation_fun
		case 'logistic'
			dL_di{i} = dL_di{i}.*hAct{i}.*(1 - hAct{i});
	end
end

%% compute weight penalty cost and gradients 
for i = 1:length(ei.layer_sizes)
	gradStack{i}.b = sum(dL_di{i}, 2);

	if(i == 1) acts = data; else acts = hAct{i-1}; end;

	gradStack{i}.W = dL_di{i}*acts';
end

%% compute weight penalty cost and gradient for non-bias terms
%%% YOUR CODE HERE %%%
wCost = 0;

for i = 1:length(gradStack)
	wCost += sum(stack{i}.W(:) .^ 2);
end
wCost *= 0.5*ei.lambda;

cost = ceCost + wCost;

for i = 1:length(gradStack)		
	gradStack{i}.W += ei.lambda*stack{i}.W;
end
	
%% reshape gradients into vector
[grad] = stack2params(gradStack);
end



