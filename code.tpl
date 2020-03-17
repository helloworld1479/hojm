{include file='user/main.tpl'}

<main class="content">
    <div class="content-header ui-content-header">
        <div class="container">
            <h1 class="content-heading">充值与教程</h1>


        </div>
    </div>
    <div class="container">
        <section class="content-inner margin-top-no">
            <div class="row">

                <div class="col-lg-12 col-md-12">
                    <div class="card margin-bottom-no">
                        <div class="card-main">
                            <div class="card-inner">
                                <div class="card-inner">
                                    <p class="card-heading">注意!</p>
                                    <p>充值完成后需刷新网页以查看余额，通常一分钟内到账。</p>
                                    <p>因余额不足而未能完成的自动续费，在余额足够时会自动划扣续费。</p>
                                    {if $config["enable_admin_contact"] == 'true'}
                                        <p class="card-heading">教程在充值的下面。</p>
                                        <p class="card-heading">如果没有到账请立刻联系管理员：</p>
                                        {if $config["admin_contact1"]!=null}
                                            <li>{$config["admin_contact1"]}</li>
                                        {/if}
                                        {if $config["admin_contact2"]!=null}
                                            <li>{$config["admin_contact2"]}</li>
                                        {/if}
                                        {if $config["admin_contact3"]!=null}
                                            <li>{$config["admin_contact3"]}</li>
                                        {/if}
                                    {/if}
                                    <br/>
                                    <p><i class="icon icon-lg">attach_money</i>当前余额：<font color="#399AF2" size="5">{$user->money}</font> 元</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>


                {if $pmw!=''}
                    <div class="col-lg-12 col-md-12">
                        <div class="card margin-bottom-no">
                            <div class="card-main">
                                <div class="card-inner">
                                    {$pmw}
                                </div>
                            </div>
                        </div>
                    </div>
                {/if}

                {if $bitpay!=''}
                    <div class="col-lg-12 col-md-12">
                        <div class="card margin-bottom-no">
                            <div class="card-main">
                                <div class="card-inner">
                                    {$bitpay}
                                </div>
                            </div>
                        </div>
                    </div>
                {/if}

                <div class="col-lg-12 col-md-12">
                    <div class="card margin-bottom-no">
                        <div class="card-main">
                            <div class="card-inner">
                                <div class="card-inner">
                                    <div class="cardbtn-edit">
                                        <div class="card-heading">充值码</div>
                                        <button class="btn btn-flat" id="code-update">
                                            <span class="icon">favorite_border</span>
                                        </button>
                                    </div>
                                    <div class="form-group form-group-label">
                                        <label class="floating-label" for="code">充值码</label>
                                        <input class="form-control maxwidth-edit" id="code" type="text">
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-12 col-md-12">
                    <div class="card margin-bottom-no">
                        <div class="card-main">
                            <div class="card-inner">
                                <div class="card-inner">
                                    <div class="cardbtn-edit">
                                        <div class="card-heading">教程（请先复制 用户中心-快速使用-的vmess订阅链接）</div>
                                        <button class="btn btn-flat" id="code-update">
                                            <span class="icon">favorite_border</span>
                                        </button>
                                    </div>
								<nav class="tab-nav margin-top-no">
									<ul class="nav nav-list">
										<li class="active">
											<a class="" data-toggle="tab" href="#sub_center_windows"><i class="icon icon-lg">desktop_windows</i>&nbsp;Windows</a>
										</li>
										<li>
										    <a class="" data-toggle="tab" href="#sub_center_mac"><i class="icon icon-lg">laptop_mac</i>&nbsp;MacOS</a>
										</li>
										<li>
											<a class="" data-toggle="tab" href="#sub_center_ios"><i class="icon icon-lg">phone_iphone</i>&nbsp;iOS</a>
										</li>
										<li>
											<a class="" data-toggle="tab" href="#sub_center_android"><i class="icon icon-lg">android</i>&nbsp;Android</a>
										</li>
									</ul>
								</nav>
											<div class="tab-pane fade active in" id="sub_center_windows">
												<p><span class="icon icon-lg text-white">filter_00</span> <a class="btn-dl" href="https://github.com/Fndroid/clash_for_windows_pkg/releases"><i class="material-icons">save_alt</i> 下载</a> Clash for Windows - [ SS/VMess ]：</p>
													<p>教程文档：<a class="btn-dl" href="/doc/#/Windows/Clash-for-Windows"><i class="material-icons icon-sm">how_to_vote</i>点击查看</a></p>
													<p>使用方式：<a class="btn-dl" href="{$subInfo["clash"]}"><i class="material-icons icon-sm">how_to_vote</i>配置下载</a>.<a class="btn-dl" href="clash://install-config?url={urlencode($subInfo["clash"])}"><i class="material-icons icon-sm">how_to_vote</i>Clash for Windows 一键导入</a></p>
                                            	<hr/>
												<p><span class="icon icon-lg text-white">filter_1</span> <a class="btn-dl" href="https://github.com/2dust/v2rayN/releases/download/2.30/v2rayN-Core.zip"><i class="material-icons">save_alt</i> 下载</a> [ v2rayN ]：</p>
												<p><span class="icon icon-lg text-white">filter_2</span> 下载解压，打开v2rayn.exe。打开软件点击订阅-点击订阅设置。</p>
												<img src="/images/w1.png" width="599">
												<p><span class="icon icon-lg text-white">filter_3</span> 点击订阅设置。把复制的vemss订阅链接复制到url，备注东方互联。点击完成。</p>
												<img src="/images/w2.png" width="599">
												<p><span class="icon icon-lg text-white">filter_4</span> 返回到主界面点击订阅-更新订阅。在节点列表中选择你要用的节点，右击，设为活动服务器。</p>
												<img src="/images/w1.png" width="599">
												<p><span class="icon icon-lg text-white">filter_2</span> 然后在界面选择参数设置，本地监听端口1080</p>
												<img src="/images/w3.png" width="599">
												<p><span class="icon icon-lg text-white">filter_5</span> 在桌面右下角托盘找到v2rayn的软件图标右击-勾选启用http代理，然后http代理模式自行选择，如果不会建议全局。</p>
												<img src="/images/4.jpeg" width="599">
											</div>
											<div class="tab-pane fade" id="sub_center_mac">
												<p><span class="icon icon-lg text-white">filter_1</span> <a class="btn-dl" href="https://github.com/yanue/V2rayU/releases/download/1.4.1/V2rayU.dmg"><i class="material-icons">save_alt</i> 下载</a> [ v2rayU ]：</p>
												<p><span class="icon icon-lg text-white">filter_1</span> 下载安装 V2rayU.dmg，拖拽/复制 V2rayU.app 文件至 Mac 应用程序，打开 V2rayU.app，并给到相应授权（进入系统偏好设置-）。</p>
												
												<p><span class="icon icon-lg text-white">filter_2</span> Mac 顶部，找到 V2rayU图标，点击，点击Configure</p>
												
												<p><span class="icon icon-lg text-white">filter_3</span> 找到subscribe按钮，仍然是熟悉的套路。复制 订阅链接 订阅信息，并粘贴至 URL处，remark（即备注）处，随意填写。填写完毕后，点击add按钮，完成添加订阅的设置。</p>
											
												<p><span class="icon icon-lg text-white">filter_4</span> 点击update servers 按钮，更新订阅（下载节点配置信息，你会看到更新日志）。Mac 顶部，找到 V2rayU图标，点击，点击turn v2ray-core on。然后打开 google.com/hk 试试</p>
											
											</div>

											<div class="tab-pane fade" id="sub_center_ios">
											     <p><span class="icon icon-lg text-white">filter_1</span>
											   复制用户中心-快速使用-vemss订阅链接。然后进入shadowrocket软件。（ios请在商店登陆美区账号，下载小飞机，价值3美元。账号和充值卡淘宝均有卖。官网五元或者买年费套餐赠送。具体联系客服。）第一步打开小飞机，右上角加号点一下。</p>
												 <img src="/images/i1.jpg" width="321">
												 <p><span class="icon icon-lg text-white">filter_2</span> 按照下面设置选择。订阅地址粘贴到2处，备注东方木。点击右上角对号。退出软件再打开，自动更新订阅，
选择需要的节点开启就可以了！</p>
												 <img src="/images/i2.jpg" width="321">
											</div>

											<div class="tab-pane fade" id="sub_center_android">
												<p><span class="icon icon-lg text-white">filter_1</span> <a class="btn-dl" href="https://github.com/2dust/v2rayNG/releases/download/1.1.6/app-arm64-v8a-release.apk"><i class="material-icons">save_alt</i> 下载</a> [ v2rayNG ]：</p>
												<p><span class="icon icon-lg text-white">filter_2</span> 下载软件，复制用户中心-快速使用-vemss订阅链接。然后进入v2rayng软件，点左上角三条杠。</p>
												<img src="/images/a1.jpg" width="321">
												<p><span class="icon icon-lg text-white">filter_3</span> 点订阅设置。</p>
												<img src="/images/a2.jpg" width="321">
												<p><span class="icon icon-lg text-white">filter_4</span> 点添加</p>
												<img src="/images/a3.jpg" width="321">
												<p><span class="icon icon-lg text-white">filter_5</span> 将刚才复制的订阅链接复制到url里，备注写东方木。点击右上角完成。</p>
												<img src="/images/a4.jpg" width="321">
												<p><span class="icon icon-lg text-white">filter_6</span> 回到主界面。点右上角三个点。</p>
												<img src="/images/a6.jpg" width="321">
												<p><span class="icon icon-lg text-white">filter_7</span> 点更新订阅。稍等片刻！更新出来节点以后，点击以东方互联开头的节点，然后点右下角的连接。</p>
												<img src="/images/a5.jpg" width="321">
												<p><span class="icon icon-lg text-white">filter_7</span> 关于分应用代理的设置，（可用可不用，设置省电。）点击左上角的三个杠-设置。</p>
												<img src="/images/11.jpg" width="321">
												<p><span class="icon icon-lg text-white">filter_7</span> 选择分应用代理。</p>
												<img src="/images/12.jpg" width="321">
												<p><span class="icon icon-lg text-white">filter_7</span> 需要代理的应用打勾，不需要的不打，上面的分应用代理选项打开。完毕！</p>
												<img src="/images/13.jpg" width="321">
												<hr/>
											</div>
											</div>
                            </div>
                        </div>
                    </div>
                </div>                
        
                <div class="col-lg-12 col-md-12">
                    <div class="card margin-bottom-no">
                        <div class="card-main">
                            <div class="card-inner">

                                <div class="card-table">
                                    <div class="table-responsive table-user">
                                        {$codes->render()}
                                        <table class="table table-hover">
                                            <tr>
                                                <!--<th>ID</th> -->
                                                <th>代码</th>
                                                <th>类型</th>
                                                <th>操作</th>
                                                <th>使用时间</th>

                                            </tr>
                                            {foreach $codes as $code}
                                                {if $code->type!=-2}
                                                    <tr>
                                                        <!--	<td>#{$code->id}</td>  -->
                                                        <td>{$code->code}</td>
                                                        {if $code->type==-1}
                                                            <td>金额充值</td>
                                                        {/if}
                                                        {if $code->type==10001}
                                                            <td>流量充值</td>
                                                        {/if}
                                                        {if $code->type==10002}
                                                            <td>用户续期</td>
                                                        {/if}
                                                        {if $code->type>=1&&$code->type<=10000}
                                                            <td>等级续期 - 等级{$code->type}</td>
                                                        {/if}
                                                        {if $code->type==-1}
                                                            <td>充值 {$code->number} 元</td>
                                                        {/if}
                                                        {if $code->type==10001}
                                                            <td>充值 {$code->number} GB 流量</td>
                                                        {/if}
                                                        {if $code->type==10002}
                                                            <td>延长账户有效期 {$code->number} 天</td>
                                                        {/if}
                                                        {if $code->type>=1&&$code->type<=10000}
                                                            <td>延长等级有效期 {$code->number} 天</td>
                                                        {/if}
                                                        <td>{$code->usedatetime}</td>
                                                    </tr>
                                                {/if}
                                            {/foreach}
                                        </table>
                                        {$codes->render()}
                                    </div>
                                </div>


                            </div>
                        </div>
                    </div>
                </div>
                <div aria-hidden="true" class="modal modal-va-middle fade" id="readytopay" role="dialog" tabindex="-1">
                    <div class="modal-dialog modal-xs">
                        <div class="modal-content">
                            <div class="modal-heading">
                                <a class="modal-close" data-dismiss="modal">×</a>
                                <h2 class="modal-title">正在连接支付网关</h2>
                            </div>
                            <div class="modal-inner">
                                <p id="title">感谢您对我们的支持，请耐心等待</p>
                            </div>
                        </div>
                    </div>
                </div>

                {include file='dialog.tpl'}
            </div>
        </section>
    </div>
</main>
<script>
    $(document).ready(function () {
        $("#code-update").click(function () {
            $.ajax({
                type: "POST",
                url: "code",
                dataType: "json",
                data: {
                    code: $$getValue('code')
                },
                success: (data) => {
                    if (data.ret) {
                        $("#result").modal();
                        $$.getElementById('msg').innerHTML = data.msg;
                        window.setTimeout("location.href=window.location.href", {$config['jump_delay']});
                    } else {
                        $("#result").modal();
                        $$.getElementById('msg').innerHTML = data.msg;
                        window.setTimeout("location.href=window.location.href", {$config['jump_delay']});
                    }
                },
                error: (jqXHR) => {
                    $("#result").modal();
{literal}
                    $$.getElementById('msg').innerHTML = `发生错误：${jqXHR.status}`;
{/literal}
                }
            })
        })
    })
</script>

{include file='user/footer.tpl'}
