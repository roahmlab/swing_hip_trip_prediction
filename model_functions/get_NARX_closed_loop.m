function [netc, x, xi, ai] = get_NARX_closed_loop( X, T, inputDelays, feedbackDelayLength, hiddenLayerSize, trainFcn )

    feedbackDelays = 1:feedbackDelayLength;
    
    net = narxnet(inputDelays,feedbackDelays,hiddenLayerSize,'open',trainFcn);
    net.trainParam.epochs = 500000;
    [x,xi,ai,t] = preparets(net,X,{},T);

    net.divideFcn = '';
    [net,tr] = train(net,x,t,xi,ai);
    
    %Closed Loop Network
    netc = closeloop(net,xi,ai);
    netc.name = [net.name ' - Closed Loop'];

end