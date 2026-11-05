-- SScript 0.2 - Carmesim - FARM ADAPTATIVO EXPERIMENTAL
-- Nao testado no Roblox/Delta. Nenhuma garantia de indetectabilidade.
-- Missoes normais no mar atual; Beli pelas recompensas reais.
-- Nao automatiza desbloqueio dos mares, puzzles ou habilidades de frutas.
-- Referencias de integracao (nenhum codigo externo e baixado):
-- https://github.com/PlockScripts/BloxFruits/blob/main/Utils/Module.luau
-- https://gist.github.com/robloxscriptings/102258023d59f5636bf44be10d34130b
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local TS=game:GetService('TweenService')
local UIS=game:GetService('UserInputService')
local player=assert(Players.LocalPlayer,'Execute no cliente.')
local pg=assert(player:WaitForChild('PlayerGui',15),'PlayerGui indisponivel.')
local old=pg:FindFirstChild('SScript')
if old then old:Destroy() end
local sea=({[2753915549]=1,[85211729168715]=1,[113741252407134]=1,[114279672983750]=1,[4442272183]=2,[79091703265657]=2,[7449423635]=3,[100117331123089]=3})[game.PlaceId]
local cfg={mode='Nivel',weapon='Melee',speed=80,attackDelay=0.45}
local alive,running,busy=true,false,false
local generation=0
local tween,remote,quests,npcs,currentQuest
local pending,modulePending=false,false
local connections,history={},{}
local initialBeli,initialLevel
local started=os.clock()
local crimson=Color3.fromRGB(220,20,60)
local function make(class,props,parent)
    local obj=Instance.new(class)
    for k,v in pairs(props) do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function corner(obj) make('UICorner',{CornerRadius=UDim.new(0,10)},obj) end
local gui=make('ScreenGui',{Name='SScript',ResetOnSpawn=false,DisplayOrder=90},pg)
local panel=make('Frame',{Size=UDim2.fromOffset(290,320),Position=UDim2.new(0.5,-145,0.5,-160),BackgroundColor3=Color3.fromRGB(24,17,23),BorderSizePixel=0},gui)
corner(panel)
make('UIStroke',{Color=crimson,Thickness=2},panel)
local header=make('TextLabel',{Size=UDim2.new(1,-50,0,40),Position=UDim2.fromOffset(8,0),BackgroundTransparency=1,Text='SScript / 0.2 EXPERIMENTAL',TextSize=13,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,Active=true},panel)
local bubble=make('TextButton',{Size=UDim2.fromOffset(46,46),Position=UDim2.new(0,10,0.5,-23),Text='SS',TextSize=18,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=crimson},gui)
corner(bubble)
local hide=make('TextButton',{Size=UDim2.fromOffset(36,30),Position=UDim2.new(1,-42,0,5),Text='—',TextSize=18,TextColor3=Color3.new(1,1,1),BackgroundColor3=crimson},panel)
corner(hide)
local scroll=make('ScrollingFrame',{Position=UDim2.fromOffset(10,44),Size=UDim2.new(1,-20,1,-54),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},panel)
make('UIListLayout',{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
local order=0
local function row(class,text,height)
    order=order+1
    local obj=make(class,{Size=UDim2.new(1,-7,0,height),LayoutOrder=order,Text=text,TextWrapped=true,TextSize=13,TextColor3=Color3.fromRGB(244,230,235),Font=Enum.Font.Gotham,BackgroundColor3=Color3.fromRGB(47,29,39),BorderSizePixel=0},scroll)
    corner(obj)
    return obj
end
local stats=row('TextLabel','Lendo dados...',44)
local status=row('TextLabel','Parado. Escolha modo e arma.',70)
local modeButton=row('TextButton','Modo: Nivel + Beli',34)
local weaponButton=row('TextButton','Arma: Melee (combate)',34)
local toggle=row('TextButton','INICIAR',38)
toggle.BackgroundColor3=crimson
local inspect=row('TextButton','VERIFICAR COMPATIBILIDADE',34)
local travel=row('TextButton','TENTAR PROXIMO MAR (ja desbloqueado)',38)
local copy=row('TextButton','COPIAR DIAGNOSTICO',34)
local close=row('TextButton','ENCERRAR',34)
row('TextLabel','Role para ver os controles. Farm no mar atual. Troca de mar exige acesso liberado e executar novamente. Sem anti-ban.',76)
local function connect(signal,fn)
    local c=signal:Connect(fn)
    table.insert(connections,c)
    return c
end
local function say(message)
    if not alive then return end
    message=tostring(message)
    status.Text=message
    if history[#history]~=message then
        table.insert(history,message)
        if #history>15 then table.remove(history,1) end
    end
end
local function stop(message)
    running=false
    generation=generation+1
    if tween then tween:Cancel(); tween=nil end
    if alive then toggle.Text='INICIAR'; say(message or 'Parado.') end
end
local function active(token) return alive and running and token==generation end
connect(gui.Destroying,function()
    stop()
    alive=false
    for _,c in ipairs(connections) do c:Disconnect() end
end)
connect(close.Activated,function() gui:Destroy() end)
connect(bubble.Activated,function() panel.Visible=not panel.Visible end)
connect(hide.Activated,function() panel.Visible=false end)
-- Arraste o cabecalho. Todos os eventos globais sao limpos ao encerrar.
local dragInput,dragOrigin,panelOrigin
connect(header.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragInput=input; dragOrigin=input.Position; panelOrigin=panel.Position
    end
end)
connect(UIS.InputChanged,function(input)
    if not dragInput then return end
    if input==dragInput or (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then
        local delta=input.Position-dragOrigin
        local view=gui.AbsoluteSize
        local x=panelOrigin.X.Scale*view.X+panelOrigin.X.Offset+delta.X
        local y=panelOrigin.Y.Scale*view.Y+panelOrigin.Y.Offset+delta.Y
        panel.Position=UDim2.fromOffset(math.clamp(x,0,math.max(0,view.X-panel.AbsoluteSize.X)),math.clamp(y,0,math.max(0,view.Y-panel.AbsoluteSize.Y)))
    end
end)
connect(UIS.InputEnded,function(input) if input==dragInput then dragInput=nil end end)
connect(modeButton.Activated,function()
    if busy then say('Pare antes de trocar o modo.'); return end
    cfg.mode=cfg.mode=='Nivel' and 'Dinheiro' or 'Nivel'
    modeButton.Text=cfg.mode=='Nivel' and 'Modo: Nivel + Beli' or 'Modo: Beli (continua no nivel maximo)'
end)
connect(weaponButton.Activated,function()
    if busy then say('Pare antes de trocar a arma.'); return end
    cfg.weapon=cfg.weapon=='Melee' and 'Sword' or 'Melee'
    weaponButton.Text='Arma: '..cfg.weapon
end)
local function dataValue(name)
    local data=player:FindFirstChild('Data')
    local value=data and data:FindFirstChild(name)
    return value and tonumber(value.Value)
end
local function character()
    local char=player.Character
    local root=char and char:FindFirstChild('HumanoidRootPart')
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    if root and hum and hum.Health>0 then return char,root,hum end
end
local function position(value)
    if typeof(value)=='CFrame' then return value end
    if typeof(value)=='Vector3' then return CFrame.new(value) end
    if typeof(value)=='Instance' then
        if value:IsA('BasePart') then return value.CFrame end
        if value:IsA('Model') then return value:GetPivot() end
    end
end
local function clean(name) return (tostring(name):gsub('%s*%b[]',''):gsub('%s+$','')) end
local function initialize()
    assert(sea,'PlaceId nao cadastrado: '..game.PlaceId)
    local remotes=RS:FindFirstChild('Remotes')
    remote=remotes and remotes:FindFirstChild('CommF_')
    assert(remote and remote:IsA('RemoteFunction'),'CommF_ nao encontrado.')
    assert(workspace:FindFirstChild('Enemies'),'Enemies nao encontrado.')
    if not quests then
        assert(not modulePending,'Uma leitura anterior dos modulos ainda esta pendente.')
        local qm=assert(RS:FindFirstChild('Quests'),'Modulo Quests indisponivel.')
        local gm=assert(RS:FindFirstChild('GuideModule'),'GuideModule indisponivel.')
        local done,ok,q,g=false,false,nil,nil
        modulePending=true
        task.spawn(function()
            ok,q,g=pcall(function() return require(qm),require(gm) end)
            modulePending=false; done=true
        end)
        local deadline=os.clock()+8
        repeat task.wait(0.1) until done or not alive or not running or os.clock()>deadline
        assert(done,'Leitura dos modulos cancelada ou excedeu 8 segundos.')
        assert(ok,'Executor nao conseguiu ler os modulos: '..tostring(q))
        assert(type(q)=='table' and type(g)=='table' and type(g.Data)=='table','Formato dos modulos mudou.')
        assert(type(g.Data.NPCList)=='table','NPCList indisponivel.')
        quests=q; npcs=g.Data.NPCList
    end
end
local function npcPosition(id,level)
    local fallback,ambiguous=nil,false
    for _,entry in pairs(npcs) do
        if type(entry)=='table' then
            local pos=position(entry.Position)
            if pos then
                for _,v in pairs(entry) do if v==id then return pos end end
                if type(entry.Levels)=='table' then
                    for _,lv in pairs(entry.Levels) do
                        if lv==level then
                            if fallback and (fallback.Position-pos.Position).Magnitude>10 then ambiguous=true end
                            fallback=pos
                        end
                    end
                end
            end
        end
    end
    if not ambiguous then return fallback end
end
local excluded={BartiloQuest=true,CitizenQuest=true,MarineQuest=true}
local function chooseQuest(level)
    local low=sea==1 and 0 or (sea==2 and 700 or 1500)
    local high=sea==1 and 700 or (sea==2 and 1500 or math.huge)
    local best
    for id,group in pairs(quests) do
        if type(group)=='table' and not excluded[id] then
            for index,quest in pairs(group) do
                if type(index)=='number' and type(quest)=='table' and type(quest.LevelReq)=='number' and type(quest.Task)=='table' then
                    local lv=quest.LevelReq
                    local mob,count=next(quest.Task)
                    if lv>=low and lv<high and lv<=level and type(mob)=='string' and type(count)=='number' and count>1 and not next(quest.Task,mob) then
                        local pos=npcPosition(id,lv)
                        if pos and (not best or lv>best.level or (lv==best.level and tostring(id)<tostring(best.id))) then
                            best={id=id,index=index,level=lv,mob=mob,npc=pos}
                        end
                    end
                end
            end
        end
    end
    assert(best,'Nenhuma missao normal compativel encontrada no mar atual.')
    return best
end
local function questFrame()
    local main=pg:FindFirstChild('Main')
    return main and main:FindFirstChild('Quest')
end
local function matchesQuest(frame,mob)
    for _,obj in ipairs(frame:GetDescendants()) do
        if (obj:IsA('TextLabel') or obj:IsA('TextButton')) and string.find(string.lower(obj.Text),string.lower(mob),1,true) then return true end
    end
    return false
end
-- Uma requisicao pendente por vez; timeout nao gera novas requisicoes.
local function callRemote(token,...)
    assert(not pending,'Requisicao anterior pendente. Aguarde ou reentre no jogo.')
    if not active(token) then return false end
    local args=table.pack(...)
    local done,ok,result=false,false,nil
    pending=true
    task.spawn(function()
        ok,result=pcall(function() return remote:InvokeServer(table.unpack(args,1,args.n)) end)
        pending=false; done=true
    end)
    local deadline=os.clock()+10
    repeat task.wait(0.1) until done or not active(token) or os.clock()>deadline
    if not active(token) then return false end
    assert(done,'Servidor sem resposta por 10s; farm interrompido.')
    assert(ok,'Falha na requisicao: '..tostring(result))
    return true,result
end
local function moveTo(destination,token)
    if not active(token) then return false end
    local _,root=character()
    if not root then return false end
    local distance=(root.Position-destination.Position).Magnitude
    if distance<5 then return true end
    assert(distance<18000,'Destino exige entrada especial. Va ate a ilha manualmente e reinicie.')
    local duration=math.max(distance/cfg.speed,0.1)
    local t=TS:Create(root,TweenInfo.new(duration,Enum.EasingStyle.Linear),{CFrame=destination})
    tween=t; t:Play()
    local deadline=os.clock()+duration+3
    repeat
        task.wait(0.1)
        local _,currentRoot=character()
        if currentRoot~=root then break end
    until not active(token) or t.PlaybackState~=Enum.PlaybackState.Playing or os.clock()>deadline
    t:Cancel()
    if tween==t then tween=nil end
    if not active(token) then return false end
    local _,currentRoot=character()
    if currentRoot~=root then return false end
    assert((root.Position-destination.Position).Magnitude<15,'Movimento bloqueado/corrigido. Va ate a ilha manualmente.')
    return true
end
local function equipped()
    local char,_,hum=character()
    if not char then return nil end
    local tool=char:FindFirstChildOfClass('Tool')
    if tool and tool.ToolTip==cfg.weapon then return tool end
    local backpack=player:FindFirstChildOfClass('Backpack')
    if backpack then
        for _,item in ipairs(backpack:GetChildren()) do
            if item:IsA('Tool') and item.ToolTip==cfg.weapon then hum:EquipTool(item); return item end
        end
    end
    error('Nenhuma arma '..cfg.weapon..'. Equipe Combat/espada ou troque a categoria.')
end
local function findEnemy(mob)
    local _,root=character()
    if not root then return nil end
    local best,distance=nil,math.huge
    for _,enemy in ipairs(workspace.Enemies:GetChildren()) do
        local hum=enemy:FindFirstChildOfClass('Humanoid')
        local part=enemy:FindFirstChild('HumanoidRootPart')
        if clean(enemy.Name)==mob and hum and hum.Health>0 and part then
            local d=(root.Position-part.Position).Magnitude
            if d<distance then best=enemy; distance=d end
        end
    end
    return best
end
local spawnCache={}
local function spawnPosition(mob)
    if spawnCache[mob] then return spawnCache[mob] end
    local world=workspace:FindFirstChild('_WorldOrigin')
    local folders={[1]=world and world:FindFirstChild('EnemySpawns'),[2]=RS:FindFirstChild('FortBuilderReplicatedSpawnPositionsFolder')}
    for i=1,2 do
        local folder=folders[i]
        if folder then
            for _,obj in ipairs(folder:GetChildren()) do
                if clean(obj.Name)==mob then
                    local pos=position(obj)
                    if pos then spawnCache[mob]=pos; return pos end
                end
            end
        end
    end
end
local function fight(enemy,token)
    local hum=enemy:FindFirstChildOfClass('Humanoid')
    local part=enemy:FindFirstChild('HumanoidRootPart')
    if not hum or not part then return end
    local lastHealth,lastDamage=hum.Health,os.clock()
    while active(token) and enemy.Parent and hum.Health>0 and part.Parent do
        local char,root,ownHum=character()
        if not char then return end
        local q=questFrame()
        if not q or not q.Visible then return end
        if ownHum.Health/ownHum.MaxHealth<0.2 then
            say('Vida baixa; recuando para recuperar...')
            if not moveTo(root.CFrame*CFrame.new(0,0,45),token) then return end
            local deadline=os.clock()+45
            repeat
                task.wait(0.5)
                char,root,ownHum=character()
            until not active(token) or not char or ownHum.Health/ownHum.MaxHealth>=0.75 or os.clock()>deadline
            if not char or not active(token) then return end
            assert(ownHum.Health/ownHum.MaxHealth>=0.75,'Recuperacao demorou demais; farm parado.')
            lastDamage=os.clock()
        end
        if not active(token) then return end
        local tool=equipped()
        if not tool then return end
        say('Atacando: '..enemy.Name)
        if (root.Position-part.Position).Magnitude>5 then
            if not moveTo(part.CFrame*CFrame.new(0,0,3),token) then return end
        end
        if active(token) and tool.Parent==char and part.Parent then
            local look=Vector3.new(part.Position.X,root.Position.Y,part.Position.Z)
            if (look-root.Position).Magnitude>0.01 then root.CFrame=CFrame.lookAt(root.Position,look) end
            tool:Activate()
        end
        if hum.Health<lastHealth then lastDamage=os.clock() end
        lastHealth=hum.Health
        assert(os.clock()-lastDamage<20,'Sem dano por 20s. Ataque nao funcionou ou alvo esta inacessivel.')
        task.wait(cfg.attackDelay)
    end
end
local function farm(token)
    initialize()
    if not active(token) then return end
    local cap=tonumber(player:GetAttribute('LevelCap'))
    if cfg.mode=='Nivel' then assert(cap and cap>0,'LevelCap nao detectado. Modo Nivel precisa desse atributo; use Beli para farm continuo.') end
    local waitMobSince=nil
    while active(token) do
        local level=assert(dataValue('Level'),'Data.Level indisponivel.')
        if cfg.mode=='Nivel' and level>=cap then stop('Nivel maximo informado pelo jogo atingido: '..cap); return end
        local char=character()
        if not char then
            say('Aguardando renascimento...'); currentQuest=nil; waitMobSince=nil; task.wait(1)
        else
            equipped()
            local q=assert(questFrame(),'Interface Main.Quest mudou; envie o diagnostico.')
            if q.Visible then
                if not currentQuest then
                    local candidate=chooseQuest(level)
                    assert(matchesQuest(q,candidate.mob),'Missao ativa diferente/texto traduzido. Finalize ou cancele a missao e use idioma ingles.')
                    currentQuest=candidate
                end
                assert(matchesQuest(q,currentQuest.mob),'A missao ativa mudou ou o texto nao esta em ingles.')
                local enemy=findEnemy(currentQuest.mob)
                if enemy then
                    waitMobSince=nil
                    fight(enemy,token)
                else
                    waitMobSince=waitMobSince or os.clock()
                    assert(os.clock()-waitMobSince<90,'Inimigo nao encontrado em 90s: '..currentQuest.mob)
                    local spawn=spawnPosition(currentQuest.mob)
                    assert(spawn,'Spawn nao encontrado: '..currentQuest.mob..'. Visite a ilha para carregar os dados.')
                    say('Aguardando spawn: '..currentQuest.mob)
                    moveTo(spawn*CFrame.new(0,3,0),token)
                    task.wait(1)
                end
            else
                currentQuest=chooseQuest(level)
                waitMobSince=nil
                say('Missao: '..currentQuest.mob..' / nivel '..currentQuest.level)
                if moveTo(currentQuest.npc*CFrame.new(0,0,3),token) then
                    local called=callRemote(token,'StartQuest',currentQuest.id,currentQuest.index)
                    if called then
                        local deadline=os.clock()+5
                        repeat task.wait(0.2) until not active(token) or q.Visible or os.clock()>deadline
                        if active(token) then assert(q.Visible,'Missao nao aceita. Verifique NPC e identificador '..currentQuest.id) end
                    end
                end
            end
            task.wait(0.2)
        end
    end
end
local function launch(fn)
    if busy then say('Aguarde a operacao anterior encerrar.'); return end
    if pending or modulePending then say('Operacao antiga pendente; aguarde ou reentre.'); return end
    busy=true; running=true; generation=generation+1
    local token=generation
    toggle.Text='PARAR'
    task.spawn(function()
        local ok,err=pcall(function() fn(token) end)
        busy=false
        if alive and token==generation then stop(ok and 'Concluido.' or tostring(err)) end
    end)
end
connect(toggle.Activated,function()
    if running then stop(); return end
    if not player.Team then say('Escolha Pirates ou Marines primeiro.'); return end
    currentQuest=nil
    launch(farm)
end)
connect(inspect.Activated,function()
    if busy then say('Pare antes de verificar.'); return end
    launch(function(token)
        initialize()
        local q=chooseQuest(assert(dataValue('Level'),'Nivel indisponivel'))
        if not active(token) then return end
        currentQuest=nil
        stop('Dados encontrados: mar '..sea..', missao '..q.id..', alvo '..q.mob..'. Combate ainda nao validado.')
    end)
end)
connect(travel.Activated,function()
    if busy then say('Pare o farm antes de viajar.'); return end
    launch(function(token)
        initialize()
        assert(sea<3,'Voce ja esta no Terceiro Mar.')
        local threshold=sea==1 and 700 or 1500
        assert((dataValue('Level') or 0)>=threshold,'Nivel necessario para tentar viagem: '..threshold)
        say('Tentando viagem. Execute o SScript novamente no destino.')
        callRemote(token,sea==1 and 'TravelDressrosa' or 'TravelZou')
        if active(token) then stop('Viagem solicitada. Se nao trocar de mar, conclua o desbloqueio manualmente.') end
    end)
end)
connect(copy.Activated,function()
    local report='SScript 0.2\nPlaceId: '..game.PlaceId..'\nMar: '..tostring(sea)..'\nNivel: '..tostring(dataValue('Level'))..'\nLevelCap: '..tostring(player:GetAttribute('LevelCap'))..'\nModo: '..cfg.mode..' / '..cfg.weapon..'\n'..table.concat(history,'\n')
    if type(setclipboard)=='function' then
        local ok=pcall(setclipboard,report)
        if ok then say('Diagnostico copiado.'); return end
    end
    warn(report)
    say('Copiar indisponivel. Diagnostico enviado ao console.')
end)
task.spawn(function()
    while alive do
        local lv,beli=dataValue('Level'),dataValue('Beli')
        initialLevel=initialLevel or lv; initialBeli=initialBeli or beli
        stats.Text=string.format('Mar %s | Nivel %s | Beli %s\nSessao: +%s niveis | Beli liquido %s | %d min',tostring(sea or '?'),tostring(lv or '?'),tostring(beli or '?'),tostring(lv and initialLevel and lv-initialLevel or 0),tostring(beli and initialBeli and beli-initialBeli or 0),math.floor((os.clock()-started)/60))
        task.wait(1)
    end
end)
