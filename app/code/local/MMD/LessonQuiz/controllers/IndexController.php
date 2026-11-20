<?php
/**
 * Public lesson quiz page, opened from the QR code the trainer shows in class
 * (or from the Take Quiz button on the learner's class page):
 *   /lessonquiz/index/index/q/<quiz id>/run/<run id>/k/<signature>
 *
 * The page is a web client of the learner API (MMD_MobileApi): the learner
 * signs in with their email (emailed code or password), the questions come
 * from GET /mobileapi/learner/quiz and the answers go to POST, where they are
 * scored and recorded. No correct answer is in the page before submitting.
 */
class MMD_LessonQuiz_IndexController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $h      = Mage::helper('mmd_lessonquiz');
        $req    = $this->getRequest();
        $quizId = (int) $req->getParam('q');
        $runId  = max(0, (int) $req->getParam('run'));
        $quiz   = $quizId > 0 ? $h->getQuiz($quizId) : null;

        $this->getResponse()
            ->setHeader('Content-Type', 'text/html; charset=UTF-8', true)
            ->setHeader('Cache-Control', 'no-store', true)
            ->setHeader('X-Robots-Tag', 'noindex, nofollow', true);

        if (!$quiz || !$quiz['questions'] || !hash_equals($h->sig($quizId, $runId), (string) $req->getParam('k'))) {
            $this->getResponse()->setHttpResponseCode(404)
                ->setBody($this->_html('Quiz', '<h1>Quiz</h1><p class="msg err">This quiz link is not valid.</p>', null));
            return;
        }

        $title = $quiz['title'] !== '' ? $quiz['title'] : 'Quiz';
        $count = count($quiz['questions']);
        $sub   = Mage::getResourceModel('catalog/product')->getAttributeRawValue($quiz['product_id'], 'name', 0);
        $body  = '<h1>' . htmlspecialchars($title) . '</h1>'
            . '<p class="sub">' . ($sub ? htmlspecialchars((string) $sub) . ' &middot; ' : '') . $count . ' question' . ($count === 1 ? '' : 's') . '</p>'
            . '<div id="app" aria-live="polite"><p class="note">Loading...</p></div>'
            . '<noscript><p class="msg err">Turn on JavaScript to take this quiz.</p></noscript>';
        $this->getResponse()->setBody($this->_html($title, $body, array(
            'api'    => Mage::getUrl('mobileapi', array('_nosid' => true)),
            'quizId' => $quizId,
            'runId'  => $runId,
            'k'      => $h->sig($quizId, $runId),
        )));
    }

    protected function _html($title, $body, $cfg)
    {
        $css = 'body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:#f1f5f9;color:#0f172a}'
            . '.card{max-width:560px;margin:24px auto;padding:26px 22px;background:#fff;border-radius:12px;box-shadow:0 1px 3px rgba(15,23,42,.12)}'
            . 'h1{font-size:22px;margin:0 0 4px}.sub{color:#475569;font-size:14px;margin:0 0 18px}'
            . 'label{display:block;font-size:14px;font-weight:600;margin:14px 0 6px}'
            . 'input[type=text],input[type=email],input[type=password]{width:100%;box-sizing:border-box;padding:12px;font-size:16px;border:1px solid #94a3b8;border-radius:8px}'
            . 'input:focus-visible,button:focus-visible{outline:3px solid #93c5fd;outline-offset:2px}'
            . '.btn{display:block;width:100%;box-sizing:border-box;margin-top:18px;padding:13px;font-size:16px;font-weight:600;color:#fff;background:#1d4ed8;border:0;border-radius:8px;cursor:pointer}'
            . '.btn[disabled]{opacity:.55;cursor:not-allowed}'
            . '.link{background:none;border:0;padding:0;margin-top:14px;color:#1d4ed8;font-size:14px;cursor:pointer;text-decoration:underline}'
            . '.msg{padding:12px;border-radius:8px;font-size:15px;margin:12px 0 0}.ok{background:#dcfce7;color:#14532d}.err{background:#fee2e2;color:#7f1d1d}'
            . '.note{color:#475569;font-size:13px;margin:12px 0 0}'
            . 'fieldset{border:1px solid #cbd5e1;border-radius:10px;margin:0 0 14px;padding:14px}'
            . 'legend{font-weight:600;font-size:15px;padding:0 6px}'
            . '.opt{display:flex;align-items:flex-start;gap:10px;margin:8px 0 0;padding:10px 12px;border:1px solid #cbd5e1;border-radius:8px;font-weight:400;font-size:15px;cursor:pointer}'
            . '.opt input{margin:3px 0 0;width:18px;height:18px;flex:0 0 auto}'
            . '.opt.right{border-color:#15803d;background:#dcfce7}.opt.wrong{border-color:#b91c1c;background:#fee2e2}'
            . '.score{font-size:30px;font-weight:700;margin:6px 0 0}.who{display:flex;justify-content:space-between;gap:10px;align-items:center;color:#475569;font-size:13px;margin:0 0 14px}'
            . '.who .link{margin:0;font-size:13px}';
        $js = $cfg === null ? '' : '<script>var QUIZ=' . json_encode($cfg, JSON_HEX_TAG | JSON_HEX_AMP | JSON_UNESCAPED_SLASHES) . ';' . $this->_js() . '</script>';
        return '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            . '<meta name="robots" content="noindex,nofollow"><title>' . htmlspecialchars($title) . '</title><style>' . $css . '</style></head>'
            . '<body><main class="card">' . $body . '</main>' . $js . '</body></html>';
    }

    /** Page script: sign in, load the quiz, submit, show the score. */
    protected function _js()
    {
        return <<<'JS'
(function(){
  var app=document.getElementById('app'),KEY='tcLmsQuizToken',token=null,email='';
  try{token=localStorage.getItem(KEY);email=localStorage.getItem(KEY+'Email')||'';}catch(e){}
  function el(tag,attrs,text){var n=document.createElement(tag),k;for(k in attrs||{}){n.setAttribute(k,attrs[k]);}if(text!=null){n.textContent=text;}return n;}
  function clear(){while(app.firstChild){app.removeChild(app.firstChild);}}
  function msg(text,cls){return el('p',{'class':'msg '+(cls||'err'),role:cls==='ok'?'status':'alert'},text);}
  function api(method,path,body){
    var opt={method:method,headers:{'Content-Type':'application/json'}};
    if(token){opt.headers.Authorization='Bearer '+token;opt.headers['X-Auth-Token']=token;}
    if(body){opt.body=JSON.stringify(body);}
    return fetch(QUIZ.api+path,opt).then(function(r){return r.json().then(function(j){j.status=r.status;return j;});});
  }
  function signedIn(j,addr){
    token=j.token;email=addr;
    try{localStorage.setItem(KEY,token);localStorage.setItem(KEY+'Email',addr);}catch(e){}
    loadQuiz();
  }
  function signOut(){
    token=null;try{localStorage.removeItem(KEY);}catch(e){}
    signIn();
  }
  function signIn(note){
    clear();
    if(note){app.appendChild(msg(note));}
    var form=el('form',{novalidate:'novalidate'});
    form.appendChild(el('label',{'for':'q-email'},'Your email'));
    var em=el('input',{id:'q-email',type:'email',autocomplete:'email',required:'required',maxlength:'320'});em.value=email;
    form.appendChild(em);
    var send=el('button',{'class':'btn',type:'submit'},'Email me a sign-in code');
    form.appendChild(send);
    var pw=el('button',{'class':'link',type:'button'},'Sign in with my password instead');
    form.appendChild(pw);
    form.appendChild(el('p',{'class':'note'},'Use the email you registered for the class with. Your score is saved to your learner account.'));
    app.appendChild(form);
    form.addEventListener('submit',function(ev){
      ev.preventDefault();
      var addr=em.value.trim().toLowerCase();
      if(!addr){em.focus();return;}
      send.disabled=true;
      api('POST','auth/otpsend',{email:addr}).then(function(j){
        if(!j.ok){signIn(j.error);return;}
        codeStep(addr);
      }).catch(function(){signIn('Could not reach the server. Please try again.');});
    });
    pw.addEventListener('click',function(){passwordStep(em.value.trim().toLowerCase());});
  }
  function codeStep(addr,note){
    clear();
    app.appendChild(msg('If '+addr+' has an account, a 6-digit code is on its way. It expires in 10 minutes.','ok'));
    if(note){app.appendChild(msg(note));}
    var form=el('form',{novalidate:'novalidate'});
    form.appendChild(el('label',{'for':'q-code'},'6-digit code'));
    var code=el('input',{id:'q-code',type:'text',inputmode:'numeric',autocomplete:'one-time-code',maxlength:'6',required:'required'});
    form.appendChild(code);
    var go=el('button',{'class':'btn',type:'submit'},'Sign in');
    form.appendChild(go);
    var back=el('button',{'class':'link',type:'button'},'Use a different email');
    form.appendChild(back);
    app.appendChild(form);code.focus();
    back.addEventListener('click',function(){signIn();});
    form.addEventListener('submit',function(ev){
      ev.preventDefault();go.disabled=true;
      api('POST','auth/otpverify',{email:addr,code:code.value.trim(),platform:'web'}).then(function(j){
        if(!j.ok){codeStep(addr,j.error);return;}
        signedIn(j,addr);
      }).catch(function(){codeStep(addr,'Could not reach the server. Please try again.');});
    });
  }
  function passwordStep(addr,note){
    clear();
    if(note){app.appendChild(msg(note));}
    var form=el('form',{novalidate:'novalidate'});
    form.appendChild(el('label',{'for':'q-email'},'Your email'));
    var em=el('input',{id:'q-email',type:'email',autocomplete:'email',required:'required',maxlength:'320'});em.value=addr||'';
    form.appendChild(em);
    form.appendChild(el('label',{'for':'q-pw'},'Password'));
    var pw=el('input',{id:'q-pw',type:'password',autocomplete:'current-password',required:'required'});
    form.appendChild(pw);
    var go=el('button',{'class':'btn',type:'submit'},'Sign in');
    form.appendChild(go);
    var back=el('button',{'class':'link',type:'button'},'Email me a sign-in code instead');
    form.appendChild(back);
    app.appendChild(form);
    back.addEventListener('click',function(){email=em.value.trim().toLowerCase();signIn();});
    form.addEventListener('submit',function(ev){
      ev.preventDefault();go.disabled=true;
      var a=em.value.trim().toLowerCase();
      api('POST','auth/password',{email:a,password:pw.value,platform:'web'}).then(function(j){
        if(!j.ok){passwordStep(a,j.error);return;}
        signedIn(j,a);
      }).catch(function(){passwordStep(a,'Could not reach the server. Please try again.');});
    });
  }
  function who(){
    var row=el('div',{'class':'who'});
    row.appendChild(el('span',null,'Signed in as '+email));
    var out=el('button',{'class':'link',type:'button'},'Not you?');
    out.addEventListener('click',signOut);
    row.appendChild(out);
    return row;
  }
  function loadQuiz(){
    clear();app.appendChild(el('p',{'class':'note'},'Loading...'));
    api('GET','learner/quiz?quiz_id='+QUIZ.quizId+'&run_id='+QUIZ.runId+'&k='+encodeURIComponent(QUIZ.k)).then(function(j){
      if(j.status===401){token=null;signIn('Please sign in again.');return;}
      if(!j.ok){clear();app.appendChild(msg(j.error||'This quiz is not available.'));return;}
      showQuiz(j.quiz,j.previous);
    }).catch(function(){clear();app.appendChild(msg('Could not reach the server. Please reload the page.'));});
  }
  function showQuiz(quiz,previous,note){
    clear();app.appendChild(who());
    if(previous){app.appendChild(msg('Your last score: '+previous.score+' / '+previous.total+'. You can take the quiz again.','ok'));}
    if(note){app.appendChild(msg(note));}
    var form=el('form',{novalidate:'novalidate'});
    quiz.questions.forEach(function(q,qi){
      var fs=el('fieldset');
      fs.appendChild(el('legend',null,(qi+1)+'. '+q.question));
      q.options.forEach(function(o,oi){
        var lab=el('label',{'class':'opt'});
        lab.appendChild(el('input',{type:'radio',name:'q_'+q.id,value:String(oi)}));
        lab.appendChild(el('span',null,o));
        fs.appendChild(lab);
      });
      form.appendChild(fs);
    });
    var go=el('button',{'class':'btn',type:'submit'},'Submit answers');
    form.appendChild(go);
    app.appendChild(form);
    form.addEventListener('submit',function(ev){
      ev.preventDefault();
      var answers={},missing=0;
      quiz.questions.forEach(function(q){
        var c=form.querySelector('input[name="q_'+q.id+'"]:checked');
        if(c){answers[q.id]=parseInt(c.value,10);}else{missing++;}
      });
      if(missing){
        var old=form.querySelector('.msg');if(old){form.removeChild(old);}
        form.insertBefore(msg('Answer every question before you submit ('+missing+' left).'),go);
        return;
      }
      go.disabled=true;
      api('POST','learner/quiz',{quiz_id:QUIZ.quizId,run_id:QUIZ.runId,k:QUIZ.k,answers:answers,platform:'web'}).then(function(j){
        if(j.status===401){token=null;signIn('Please sign in again.');return;}
        if(!j.ok){go.disabled=false;form.insertBefore(msg(j.error||'Could not submit. Please try again.'),go);return;}
        showResult(quiz,j);
      }).catch(function(){go.disabled=false;form.insertBefore(msg('Could not reach the server. Please try again.'),go);});
    });
  }
  function showResult(quiz,res){
    clear();app.appendChild(who());
    app.appendChild(el('p',{'class':'note'},'Your score'));
    app.appendChild(el('p',{'class':'score',role:'status'},res.score+' / '+res.total));
    app.appendChild(msg('Your score has been recorded.','ok'));
    var by={};res.breakdown.forEach(function(b){by[b.id]=b;});
    quiz.questions.forEach(function(q,qi){
      var b=by[q.id]||{},fs=el('fieldset');
      fs.appendChild(el('legend',null,(qi+1)+'. '+q.question+(b.correct?' (correct)':' (incorrect)')));
      q.options.forEach(function(o,oi){
        var cls='opt'+(oi===b.correct_index?' right':(oi===b.selected_index?' wrong':''));
        var tag=oi===b.correct_index?' (correct answer)':(oi===b.selected_index?' (your answer)':'');
        fs.appendChild(el('div',{'class':cls},o+tag));
      });
      app.appendChild(fs);
    });
    var again=el('button',{'class':'btn',type:'button'},'Take the quiz again');
    again.addEventListener('click',loadQuiz);
    app.appendChild(again);
  }
  if(token){loadQuiz();}else{signIn();}
})();
JS;
    }
}
