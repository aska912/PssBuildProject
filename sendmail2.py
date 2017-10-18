#!/usr/bin/env python

import smtplib, re, sys
from email.MIMEText import MIMEText

SMTP_SERVER = "127.0.0.1"
SMTP_PORT   = 25
SENDER      = "admin1830"

HandlerToMailer_NSB = {"jiemingg":	"jieming.gong", 	\
		       "xiaodoya":	"xiao_dong.yang",	\
                       "weisheli":      "Weisheng.B.Li",        \
                       "zongquat":      "Zongquan.Tian",        \
                       "xinghubl":      "Xinghua.B.Li",         \
		      }

HandlerToMailer_NOKIA = {"jibecker": "jack.becker", 	                  \
                         "vkumaara": "vinod.kumaar_avalur_elumalai.ext",  \
                        }

def HandlerToAluMail(alu_handler):
    """
        change to 
    """
    alu_domain = "sh.ad4.ad.alcatel.com"
    #alu_domain = "alcatel-sbell.com.cn"
    return alu_handler + "@" + alu_domain

def HandlerToMailAddr(handler):
    if HandlerToMailer_NSB.has_key(handler):
        return HandlerToMailAddr_NSB(handler)
    elif HandlerToMailer_NOKIA.has_key(handler):
        return HandlerToMailAddr_NOKIA(handler)
    else:
        return " "

def HandlerToMailAddr_NSB(handler):
    #domain = "nokia_sbell.com"
    domain = "sh.ad4.ad.alcatel.com"
    #return HandlerToMailer_NSB[handler] + "@" + domain
    return handler + "@" + domain

def HandlerToMailAddr_NOKIA(handler):
    domain = "nokia.com"
    return HandlerToMailer_NOKIA[handler] + "@" + domain


def SendMail(to, subject, body, text_type='text', **args):
    """
    The supported text type: text(plain), html, plain. Default is plain
    The supported argurments:
        1. cc
    """
    global SMTP_SERVER, SMTP_PORT, SENDER
  
    if text_type == 'html':
        msg = MIMEText(r"%s"%body, _subtype='html', _charset='utf8')
    else:
        msg = MIMEText(r"%s"%body, _subtype='plain')

    smtp_server   = SMTP_SERVER
    smtp_port     = SMTP_PORT
    from_addr     = SENDER

    msg['Subject'] = r"%s"%subject
    msg['From'] = from_addr

    to_addrs_list = re.split( r",|;", re.sub(r"\s+", "", to) )
    msg['To'] = ','.join(to_addrs_list)

    if args.has_key('cc'):
        cc = args['cc']
        cc_addrs_list = re.split( r"\s+|,|;", re.sub(r"\s+", "", cc) )
        msg['Cc']     = ','.join(cc_addrs_list)
        to_addrs_list += cc_addrs_list

    try:
        server = smtplib.SMTP(smtp_server, smtp_port)    
        server.sendmail( from_addr, to_addrs_list, msg.as_string() )
        server.quit()
        return True
    except:
        return False

if __name__ == '__main__':
    #to="%s,%s"%(HandlerToAluMail("jiemingg"), HandlerToAluMail("xiaodoya"))
    to = "%s"%sys.argv[1]
    new_to_addrs_list = []
    to_handlers_list = re.split( r",|;", re.sub(r"\s+", "", to) )
    for handler in to_handlers_list:
        new_to_addrs_list.append(HandlerToMailAddr(handler))
        #new_to_addrs_list.append(HandlerToAluMail(handler))
    to = ','.join(new_to_addrs_list)
    subject = "%s"%sys.argv[2]
    body = "%s"%sys.argv[3]
    print "To:      %s"%to
    print "Subject: %s"%subject
    print "Body:    \n%s"%body
    if SendMail(to, subject, body):
        sys.exit(0)
    else:
        sys.stderr.write("[sendmail.py]  Send mail failure.\n")       
        sys.exit(1)
    


