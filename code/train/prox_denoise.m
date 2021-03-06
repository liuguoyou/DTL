function [split_z_local, phi, d_phi, c] = prox_denoise(cof, split_z_init, Training, Model)
 
layerscof = reshape(cof(1:end-1), Model.len_layercof, Model.numDenoiseLayers); % discard lambda

% forward
% compute split_z^(i), phi^i(.), d_phi_i(.)
split_z_local = zeros(Training.imdims(1), Training.imdims(2), Model.numDenoiseLayers);
phi = zeros(Training.imdims(1), Training.imdims(2), Model.numFilters, Model.numDenoiseLayers);
d_phi = zeros(Training.imdims(1), Training.imdims(2), Model.numFilters, Model.numDenoiseLayers);
c = zeros(Model.numRBFs_trained, prod(Training.imdims), Model.numFilters, Model.numDenoiseLayers);

if(Training.isPreTraining)
    T = Training.PreTrain.layer;
else
    T = Model.numDenoiseLayers;
end

for i = 1:1:T
    % initialize for current layer
    if(i>1)
        split_z_old = split_z_local(:,:,i-1);
    else
        split_z_old = split_z_init;
    end
    
    % compute filter component
    filterResponse = zeros(Training.imdims);
    for j = 1:Model.numFilters
        fz = imfilter_warp(split_z_old, Model.filters2D(:,:,j,i));
        [phi(:,:,j,i), d_phi(:,:,j,i), c(:,:,j,i)] = evaluateInfluenceAndDerivative(layerscof(:,i), j, fz, Model, Training.use_gpu, Training.use_lut, i);
        filterResponse = filterResponse + imfilter_warp(phi(:,:,j,i), Model.filters2Dinv(:,:,j,i));
    end
    
    %update split_z_local for current layer
    split_z_local(:,:,i) = split_z_old - filterResponse;    % remove reaction term
     
end


end