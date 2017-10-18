#!/usr/bin/env python

import smtplib, re, sys
from email.MIMEText import MIMEText

SMTP_SERVER = "135.252.216.213"
SMTP_PORT   = 25
SENDER      = "SWIT@135.252.216.213"

def HandlerToAluMail(alu_handler):
    """
        change to 
    """
    alu_domain = "sh.ad4.ad.alcatel.com"
    #alu_domain = "alcatel-sbell.com.cn"
    return alu_handler + "@" + alu_domain

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
    to_addrs_list = re.split( r",|;", re.sub(r"\s+", "", to) )
    for addr in to_addrs_list:
        new_to_addrs_list.append(HandlerToAluMail(addr))
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
    


