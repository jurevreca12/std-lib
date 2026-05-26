FROM hpretl/iic-osic-tools:2025.07

RUN pip install --upgrade pip && \                                                                                                                                                                                                        
    pip install git+https://github.com/jurevreca12/forastero.git@09c1817 && \
    pip install git+https://github.com/cocotb/cocotb.git@c463647
                                                                                                                                                                  
WORKDIR /foss/designs/std-lib
