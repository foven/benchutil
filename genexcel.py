# import threading
# 
# local_school = threading.local()
# 
# def process_student():
#     print 'Hello, %s, %s (in %s)' % (local_school.student, local_school.teacher, threading.current_thread().name)
#     
# def process_thread(name,name_te):
#     local_school.student = name
#     local_school.teacher = name_te
#     process_student()
#     
# t1 = threading.Thread(target=process_thread, args=('Alice','tom'))
# t2 = threading.Thread(target=process_thread, args=('Bob','tim'))
# t1.start()
# t2.start()
#t1.join()
#t2.join()
# 
# import base64
# str1 = base64.b64encode('i\xb7\x1d\xfb\xef\xff')
# print str1
# 
# str1 = base64.urlsafe_b64encode('i\xb7\x1d\xfb\xef\xff')
# print str1

import os
import glob
import re
import xlwt
#from Image import init

rw = ['rw','randrw']
blocksize = ['4k', '64k', '256k', '1024k']
iodepth = ['4', '32']
numjobs = ['1']

def getResult(pathName, Rw, Bs, Iodepth, Numj):
    #print Rw, Bs, Iodepth, Numj
    for root, dirs, files in os.walk(pathName):
        Fname = glob.glob1(root,'*_rw'+Rw+'_bs'+Bs+'_io'+Iodepth+'_njob'+Numj+'.json')
        if Fname:
            filename = os.path.join(root,Fname[0])
            fd = open(filename)
            content = fd.read()
            reg = re.compile('bw=(\d*[.]?\d*)([KGM]?B)/s, iops=(\d*[.]?\d*)')
            result_bwio = reg.findall(content)
                    
            reg = re.compile('[^cs]lat \(([mu]sec)\): min=(\d*[.]?\d*), max=(\d*[.]?\d*K?), avg=[ ]?(\d*[.]\d*)')
            result_lat= reg.findall(content)
            #print result_bwio
            return result_bwio, result_lat
                
def makeTables(mySheet,pathname,methd):
    r,c = 1,1
    lens = len(iodepth)
    bwr = 1
    iopsr = bwr + lens+2
    latr = iopsr +lens + 2
    
    wbwr = latr + lens + 2
    wiopsr =wbwr + lens + 2
    wlatr = wiopsr + lens + 2
    
    initSheet(mySheet)
    
    for mIo in iodepth:
        for mBs in blocksize:
            bwio, lat = getResult(pathname,methd, mBs, mIo, '1')
            #print lat
            if bwio[0][1] == 'B':
                mySheet.write(bwr+r,c, float(bwio[0][0])/1024.0/1024.0)
            elif bwio[0][1] == 'KB':
                mySheet.write(bwr+r,c, float(bwio[0][0])/1024.0)
            elif bwio[0][1] == 'MB':
                mySheet.write(bwr+r,c, float(bwio[0][0]))
            elif bwio[0][1] == 'GB':
                mySheet.write(bwr+r,c, float(bwio[0][0])*1024)
            else:
                print 'bwio:error'
            
            mySheet.write(iopsr+r, c, int(bwio[0][2]))
            #print lat 
            if lat[0][0] == 'usec':
                mySheet.write(latr+r, c, float(lat[0][3])/1000)
            elif lat[0][0] == 'msec':
                mySheet.write(latr+r, c, float(lat[0][3]))
            else:
                print 'lat:error'
                
            if bwio[0][1] == 'B':
                mySheet.write(wbwr+r,c, float(bwio[0][0])/1024.0/1024.0)
            elif bwio[0][1] == 'KB':               
                mySheet.write(wbwr+r,c, float(bwio[1][0])/1024.0)
            elif bwio[1][1] == 'MB':
                mySheet.write(wbwr+r,c, float(bwio[1][0]))
            elif bwio[1][1] == 'GB':
                mySheet.write(wbwr+r,c, float(bwio[1][0])*1024)
            else:
                print 'bwio:error'
            
            mySheet.write(wiopsr+r, c, int(bwio[1][2]))
             
            if lat[1][0] == 'usec':
                mySheet.write(wlatr+r, c, float(lat[1][3])/1000)
            elif lat[1][0] == 'msec':
                mySheet.write(wlatr+r, c, float(lat[1][3]))
            else:
                print 'lat:error'
                
            c += 1
        r += 1
        c = 1

def initSheet(mySheet):
    r,c = 0,1
    lens = len(iodepth)
    bwr = 1
    iopsr = bwr + lens+ 2
    latr = iopsr +lens + 2
    
    wbwr = latr + lens + 2
    wiopsr =wbwr + lens + 2
    wlatr = wiopsr + lens + 2
    
    for mIo in iodepth:        
        for mBs in blocksize:
            if r == 0:
                mySheet.write(bwr,c,mBs)
                mySheet.write(iopsr,c,mBs)
                mySheet.write(latr,c,mBs)
                mySheet.write(wbwr,c,mBs)
                mySheet.write(wiopsr,c,mBs)
                mySheet.write(wlatr,c,mBs)
            else:
                break
            c += 1
        r += 1
        mySheet.write(bwr+r,0,mIo)
        mySheet.write(iopsr+r,0,mIo)
        mySheet.write(latr+r,0,mIo)
        mySheet.write(wbwr+r,0,mIo)
        mySheet.write(wiopsr+r,0,mIo)
        mySheet.write(wlatr+r,0,mIo)
        c = 1        
            
def makeSheet(book,pathname):
    for methd in rw:
        ws = book.add_sheet(methd)
        makeTables(ws, pathname, methd)
        
if __name__ == '__main__':

    wb = xlwt.Workbook()
    #ws = wb.add_sheet('A Test Sheet')
    makeSheet(wb, 'node1-1')
    wb.save('node1-1_j.xls')

# for root,dirs,files in os.walk('node2-1'):
#     FN=glob.glob1(root,'*rwrw_bs256k*.json')
#     if FN:
#         filename = os.path.join(root,FN[0])
#         fd = open(filename)
#         content = fd.read()
#         reg = re.compile('bw=(\d*[.]?\d*)([KGM]B)/s, iops=(\d*[.]?\d*)')
#         result_bwio= reg.findall(content)
#         
#         reg = re.compile('[^cs]lat \(([mu]sec)\): min=(\d*[.]?\d*), max=(\d*[.]?\d*), avg=[ ]?(\d*[.]\d*)')
#         result_lat= reg.findall(content)
#         print result_bwio, result_lat
        